#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
$Data::Dumper::Indent = 1;

######################################
############# USER INPUT #############
#####################################
#STEP 1#
my @ipaddresses = qw( 192.168.2.2 192.168.3.2 192.168.4.2 192.168.5.2 192.168.6.2 192.168.7.2 192.168.8.2 192.168.9.2 192.168.10.2 192.168.11.2 192.168.12.2  ); #Example qw( 172.16.1.1 172.16.2.1 .... 172.16.12.1 )) where "...." is a sequence of IPS.
my $time = 400 ;
my $clients = 250;
my $portbase = 443;
my $file = "256K";
my $cipher = "AES128-GCM-SHA256";
my $STIME_OUTPUT_FILE;
use constant OPENSSL_DIR => "/home/n869p538/wrk_offloadenginesupport/openssl/";
######################################
############# USER INPUT #############
######################################

#Check OpenSSL Dir is set correctly.
if(! -d "@{[OPENSSL_DIR]}") {
    printf "\n\n@{[OPENSSL_DIR]} does not exist.\n\n";
    printf "Please modify the OPENSSL_DIR variable in the User Input section!\n\n";
    exit 1;
}

use constant STIME_APP                => "@{[OPENSSL_DIR]}/apps/openssl s_time";
my @IPs              = ('127.0.0.1');

###############################################################################
sub printVariables {
    my ($servers) = @_;

    #Print out variables for check
    printf "\n Location of OpenSSL:     @{[OPENSSL_DIR]}\n";
    printf " IP Addresses:              @ipaddresses\n";
    printf " Time:                      $time\n";
    printf " Clients:                   $clients\n";
    printf " Servers:                   $servers\n";
    printf " Port Base:                 $portbase\n";
    printf " File:                      $file\n";
    printf " Cipher:                    $cipher\n\n";


    print "Press ENTER to continue";
    #<STDIN>;
}

###############################################################################
sub usage {
  print "Error: $_[0] \n" if defined $_[0];
  print <<'EOF';
Usage:

  stimefork.pl [options]

Options:

  --emulation
                  It performs a dry-run showing how many stime
                  processes would be created and all its parameters.
                  Optional.

  --help
                  Shows this help.

  --servers=number
                  Number of servers listening in the server side.
                  Mandatory.

  time=number
                  Number minimum seconds to run the test.

  portbase=number
                  Starting port number where the web servers will
                  be listening at.

  clients=number
                  Number of clients to be created per server. It all of them
                  will be requesting to the same server.

  file=filename
                  Filename to be requested from the servers.

  ip=filename
                  Filename containing the list of IP adresses where
                  the web server will be listening at.

  cipher=string
                  Cipher suite tag to be used by the clients.
                  Run openssl ciphers -v to know more about this.

  ex.) ./bulk.pl --servers 1 --cipher AES128-GCM-SHA256 --clients 2000 --time 30
EOF

  exit 1;
}

###############################################################################
sub check_mandatory_args {
  foreach (@_) {
    return 0 unless defined ${$_};
  }
  return 1;
}

###############################################################################
sub getStimeOutputFilename {
  my ($server, $child) = @_;
  return $STIME_OUTPUT_FILE . "_server${server}_child${child}.log";
}

###############################################################################
sub myfork {
  my $pid = fork();
  die "fork() failed!" if (!defined $pid);
  return $pid;
}

###############################################################################
sub Kbps2Gbps {
  return $_[0] * 8 / 1024 / 1024;
}

###############################################################################
sub Bps2Gbps {
  return $_[0] * 8 / 1024 / 1024 / 1024;
}

###############################################################################
sub getServerPort {
  my ($portbase, $servers, $child) = @_;
  return $portbase + ( $child % $servers );
}

###############################################################################
sub readCompleteFile {
  my $filename = shift;
  open my $FILE, "<", $filename;
  local $/ = undef;
  my $content = <$FILE>;
  close $FILE;
  return $content;
}

###############################################################################
# -connect host:port - host:port to connect to (default is localhost:4433)
# -nbio         - Run with non-blocking IO
# -ssl2         - Just use SSLv2
# -ssl3         - Just use SSLv3
# -bugs         - Turn on SSL bug compatibility
# -new          - Just time new connections
# -reuse        - Just time connection reuse
# -www page     - Retrieve 'page' from the site
# -time arg     - max number of seconds to collect data, default 30
# -verify arg   - turn on peer certificate verification, arg == depth
# -cert arg     - certificate file to use, PEM format assumed
# -key arg      - RSA file to use, PEM format assumed, key is in cert file
#                 file if not specified by this option
# -CApath arg   - PEM format directory of CA's
# -CAfile arg   - PEM format file of CA's
# -cipher       - preferred cipher to use, play with 'openssl ciphers'
sub call_stime {

  my ($time, $cipher, $ip, $port,
      $requested_file, $server, $child, $emulation) = @_;

  my @cmd;
  push @cmd, STIME_APP;
  push @cmd, " -connect $ip:$port";
  #push @cmd, "-nbio";
  push @cmd, "-new";
  if ($requested_file) {
    push @cmd, "-www /$requested_file";
  }
  push @cmd, "-time $time";
  if ($cipher =~ "TLS")
  {
          push @cmd, "-ciphersuites $cipher";
  }
  else
  {
          push @cmd, "-cipher $cipher";
  }
  push @cmd, ">";
  push @cmd, getStimeOutputFilename($server, $child);

  my $cmd = join(' ', @cmd);
  if ($emulation) {
    print "$cmd\n";
    exit 0;
  }
  else {
    exec $cmd;
  }
}

###############################################################################
sub checkIfDefined {
  my $Input = shift;
  if (defined($Input)) {
    return $Input;
  }
  return 0;
}

###############################################################################
sub readRateFromChildOutput {
  my $output = shift;
  # Transfer rate:          4265.90 [Kbytes/sec] received
  #$output =~ m/Transfer rate:\s*([.\d]+).*/;
  #$output =~ /real seconds/;
  # 101 connections in 2 real seconds, 3251722 bytes read per connection
  $output =~ m/(\d*) connections in (\d*) real seconds, (\d*) bytes read per connection/;
  my $conns = checkIfDefined($1);
  my $secs = checkIfDefined($2);
  my $bytes = checkIfDefined($3);
  if ($conns == 0 or $secs == 0 or $bytes == 0) {
    return 0;
  }
#  if ($bytes != 10485975)
  if ($bytes < 10000000)
  {
        printf " Whole file not transferred\n\n";
  }
  return $bytes * $conns / $secs;
}

###############################################################################
sub readLatencyFromChildOutput {
  my $output = shift;
  #               min  mean[+/-sd] median   max
  # Connect:        0    0   0.0      0       0
  $output =~ m/Connect:\s+(\d+)\s+(\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+)/;
  return checkIfDefined($2);
}

###############################################################################
sub readServerResponseTimeFromChildOutput {
  my $output = shift;
  #               min  mean[+/-sd] median   max
  # Processing:   281  286   3.6    287     293
  $output =~ m/Processing:\s+(\d+)\s+(\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+)/;
  return checkIfDefined($2);
}

###############################################################################
sub readServerConnectionsPerSecondFromChildOutput {
  my $output = shift;
  # 79 connections in 21 real seconds, 3251722 bytes read per connection
  $output =~ m/(\d*) connections in (\d*) real seconds, (\d*) bytes read per connection/;
  my $conns = checkIfDefined($1);
  my $secs = checkIfDefined($2);
  my $bytes = checkIfDefined($3);
  if ($conns == 0 or $secs == 0 or $bytes == 0) {
    return 0;
  }
  return $conns / $secs;
}

###############################################################################
sub createResultsHash {
  my $servers = shift;
  my %results;
  map {
    $results{$_} = {
      latency => 0,
      stime => 0,
      rate => 0,
      cps => 0,
    }
  }
    0..($servers-1);
  return %results;
}

###############################################################################
sub readResultsFromChildren {
  my ($clients, $servers) = @_;
  my %results = createResultsHash($servers);

  for(my $child = 0; $child < $clients; $child++) {
    my $server = $child % $servers;

    my $childoutput =
      readCompleteFile(getStimeOutputFilename($server, $child));

    $results{$server}{rate} += readRateFromChildOutput($childoutput);
    $results{$server}{latency} += readLatencyFromChildOutput($childoutput);
    $results{$server}{stime} +=
      readServerResponseTimeFromChildOutput($childoutput);
    $results{$server}{cps} += readServerConnectionsPerSecondFromChildOutput($childoutput);
  }
  return %results;
}

###############################################################################
sub showAggregatedResults {
  my ($clients, %results) = @_;

  my $rate = 0.0;
  my $latency = 0.0;
  my $servertime = 0.0;
  my $cps = 0.0;

  map {
    $rate += $results{$_}{rate};
    $latency += $results{$_}{latency};
    $servertime += $results{$_}{stime};
    $cps += $results{$_}{cps};
  }
    keys %results;

  printf " Rate:$cipher:              %6.2f Gbps (total)\n", Bps2Gbps($rate);
  printf " Latency:           %6.2f ms   (mean)\n", $latency / $clients;
  printf " Processing:        %6.2f ms   (mean)\n", $servertime / $clients;
  printf " Conns Per Second:  %6.2f cps  (total)\n", $cps;
}

###############################################################################
sub showResultsPerServer {
  my ($clients, %results) = @_;

  printf "%16s%14s%13s%16s\n",
         'Server',
         'Rate(Gbps)',
         'Latency(ms)',
         'Processing(ms)';

  my $servers = scalar keys %results;
  foreach (sort keys %results) {

    printf "%16s%8.2f%15.2f%16.2f\n",
      "$results{$_}{ip}:$results{$_}{port}",
      Bps2Gbps($results{$_}{rate}),
      $results{$_}{latency} / $clients * $servers,
      $results{$_}{stime} / $clients * $servers;
  }
}

###############################################################################
sub showResults {

  my ($clients, $servers, $portbase, @ipaddresses) = @_;
  my %results = readResultsFromChildren($clients, $servers);

  foreach (sort keys %results) {
    $results{$_}{ip} = $ipaddresses[$_ % scalar @ipaddresses];
    $results{$_}{port} = $portbase + $_;
  }

  print "\n== Results per server =======================================\n\n";
  showResultsPerServer($clients, %results);

  print "\n== Total ====================================================\n\n";
  showAggregatedResults($clients, %results);
}

###############################################################################
sub calculate_number_clients {
  my ($servers, $clients_per_server) = @_;

  my $total_clients = $servers * $clients_per_server;
  my $cpus = `nproc`;
  chomp $cpus;
  if ($total_clients > $cpus) {
    print "WARNING: total_clients ($total_clients) exceeds num cpus ($cpus)\n";
  }

  return ($total_clients, 1);
}

# main
###############################################################################

# Mandatory arguments
my $servers;

# Optional arguments
my $emulation       = 0;
my $help            = 0;

my @mandatory_args = (\$clients, \$portbase, \$time,
                      \$servers, \$cipher);

GetOptions(
  'servers=i'   => \$servers,
  'emulation'   => \$emulation,
  'help'        => \$help,
  'cipher=s'	=> \$cipher,
  'clients=i'    => \$clients,
  'time=i'      => \$time,
)
  or usage();
`rm -r /tmp`;
`mkdir -p /tmp/$cipher`;
$STIME_OUTPUT_FILE="/tmp/" . $cipher .  "/stime_output";

usage() if $help;

usage('Mandatory argument missing')
  unless check_mandatory_args(@mandatory_args);

printVariables($servers);

unlink glob $STIME_OUTPUT_FILE.'*';

my ($processes, $concurrency) = calculate_number_clients($servers, $clients);

my $ipindex = 0;
my $portsperip = $servers / scalar @ipaddresses;
my $portremainder = $servers % scalar @ipaddresses;
my $portcntr = 0;
my $cntrbase = 0;
my $remUsed = 0;
my $increment = 0;


print "Ports per IP: $portsperip Remainder: $portremainder\n";

for (my $child = 0; $child < $processes; $child++) {
  my $ip = $ipaddresses[$ipindex];
  my $port = $portbase;

  $portcntr++;

  if ($portcntr > ($portsperip + $cntrbase)) {
    if ($portremainder != 0 && $remUsed == 0) {
      $portremainder--;
      $remUsed = 1;
    }
    else {
      $ipindex++;
      $ipindex = $ipindex % scalar @ipaddresses;
      $ip = $ipaddresses[$ipindex];
      $cntrbase = ($portcntr - 1);
      $remUsed = 0;
    }
  }

  # It's utilised all the available ports
  if ($portcntr == $servers) {
    $remUsed = 0;
    $portcntr = 0;
    $ipindex = 0;
    $cntrbase = 0;
    $portremainder = $servers % scalar @ipaddresses;

  }
      if ($increment == 1000)
        {
                $increment = 0;
        }

  my $pid = myfork();

  if ($pid == 0) {
	         call_stime($time, $cipher, $ip, $port, $file ."_" . ($increment) . ".html", $child % $servers, $child, $emulation);
  }
	$increment++
}

my $i = 0;
while ($i < $processes  && (my $childpid = wait()) != -1) {
  $i++;
}

unless ($emulation) {
  @ipaddresses = ('server_ip');
  showResults($processes, $servers,
              $portbase, @ipaddresses);
}
