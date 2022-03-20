#!/bin/bash
serv_48=192.168
serv_24=2
cli_48=192.168
cli_24=1
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files

#establish servers on remote host

outfile=${wrk_output}/tcp_con_band.txt
echo -n "" >  $outfile.txt
for i in `seq 2 12`;
do 
	taskset -c $i /usr/bin/iperf -c ${serv_48}.$i.${serv_24} -B ${cli_48}.$i.${cli_24} | grep GBytes >> $outfile &
done

cat $outfile
