#!/bin/bash
dut=192.168.1.2

file=paper1

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source $WRK_ROOT/vars/environment.src

# start the default server
ssh n869p538@pollux "cd /home/n869p538/wrk_offloadenginesupport/async_nginx_build/nginx_compress_emul; ./start_default_gzip.sh"

# perform wrk benchmark
${default_wrk} -t10 -c1024  -H"accept-encoding:gzip, deflate" -d10  -s calg_req.lua http://192.168.1.2
