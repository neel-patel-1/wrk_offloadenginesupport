## SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact

This repository contains scripts for SmartDIMM MICRO'23 artifact evaluation of the 
**SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact** paper by 
Neel Patel, Amin Mamandipoor, and Mohammad Alian

### Evaluation instructions ###

* start by executing `git submodule update --init --recursive` to fetch all submodules and dependencies

The scripts in this paper can be used to reproduce:
* Figure 10: SmartDIMM Scratchpad Utilization
* Figure 11: Encrypted Nginx Performance (Nginx Server for Encrypted Files) “%” corresponds to the runtime 
increase of SPEC workload or (De)Compression throughput loss of the 
corunning LZBench benchmark
* Figure 12: SmartDIMM offloads corresponding to the "conditional" access case
when DRAM refreshes offload the data movement of a compressed page, "random"
accesses (when a target row refresh must be issued), and CPU fallbacks when
the application's compression demands exceed the capacity of SmartDIMM

### Directory Structure
* `wrk_offloadenginesupport` workload generation scripts based on the `wrk` http request generation tool
* `async_nginx_build` nginx server configuration files and builds for baseline http, https, and accelerated https using QAT and kTLS
* `Near-Memory-Sensitivity-Analysis` SmartDIMM sensitivity analysis examining the resource utilization for different server loads


# Nginx Encryption/Compression Workload Generation
Tested on
---------
Ubuntu 20.04
Kernel 5.13.0-44-generic

Bluefield 2 Mellanox NICs: part number MBF2M516A-CEEOT
Crypto PCIe Accelerators: Intel C62x Chipset QuickAssist Technology

* Figure 10:
```

```

* Figure 11:
```
```

## Basic Usage

    wrk -t12 -c400 -d30s http://127.0.0.1:8080/index.html

  This runs a benchmark for 30 seconds, using 12 threads, and keeping
  400 HTTP connections open.

  Output:

    Running 30s test @ http://127.0.0.1:8080/index.html
      12 threads and 400 connections
      Thread Stats   Avg      Stdev     Max   +/- Stdev
        Latency   635.91us    0.89ms  12.92ms   93.69%
        Req/Sec    56.20k     8.07k   62.00k    86.54%
      22464657 requests in 30.00s, 17.76GB read
    Requests/sec: 748868.53
    Transfer/sec:    606.33MB

## Command Line Options

    -c, --connections: total number of HTTP connections to keep open with
                       each thread handling N = connections/threads

    -d, --duration:    duration of the test, e.g. 2s, 2m, 2h

    -t, --threads:     total number of threads to use

    -s, --script:      LuaJIT script, see SCRIPTING

    -H, --header:      HTTP header to add to request, e.g. "User-Agent: wrk"

        --latency:     print detailed latency statistics

        --timeout:     record a timeout if a response is not received within
                       this amount of time.

## Benchmarking Tips

  The machine running wrk must have a sufficient number of ephemeral ports
  available and closed sockets should be recycled quickly. To handle the
  initial connection burst the server's listen(2) backlog should be greater
  than the number of concurrent connections being tested.

  A user script that only changes the HTTP method, path, adds headers or
  a body, will have no performance impact. Per-request actions, particularly
  building a new HTTP request, and use of response() will necessarily reduce
  the amount of load that can be generated.

## Acknowledgements

  wrk contains code from a number of open source projects including the
  'ae' event loop from redis, the nginx/joyent/node.js 'http-parser',
  and Mike Pall's LuaJIT. Please consult the NOTICE file for licensing
  details.

## Cryptography Notice

  This distribution includes cryptographic software. The country in
  which you currently reside may have restrictions on the import,
  possession, use, and/or re-export to another country, of encryption
  software. BEFORE using any encryption software, please check your
  country's laws, regulations and policies concerning the import,
  possession, or use, and re-export of encryption software, to see if
  this is permitted. See <http://www.wassenaar.org/> for more
  information.

  The U.S. Government Department of Commerce, Bureau of Industry and
  Security (BIS), has classified this software as Export Commodity
  Control Number (ECCN) 5D002.C.1, which includes information security
  software using or performing cryptographic functions with symmetric
  algorithms. The form and manner of this distribution makes it
  eligible for export under the License Exception ENC Technology
  Software Unrestricted (TSU) exception (see the BIS Export
  Administration Regulations, Section 740.13) for both object code and
  source code.
