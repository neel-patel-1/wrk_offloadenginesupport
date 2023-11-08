#!/bin/bash
dut=192.168.2.2
dut_name=pollux

file=paper1

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source $WRK_ROOT/vars/environment.src

# start the default server
ssh n869p538@${dut_name} "cd /home/n869p538/wrk_offloadenginesupport/async_nginx_build/nginx_compress_emul; ./start_default_gzip.sh"
exit
# example sw ratio flow
trim_len=$(wget --header="accept-encoding:gzip, deflate" http://${dut}/${file} 2>&1 | grep saved | awk '{print $6}' | sed -e 's/^.//' -e 's/.$//' | xargs du -b | awk '{print $1}')

# perform wrk benchmark
${default_wrk} -t10 -c1024  -H"accept-encoding:gzip, deflate" -d5  http://${dut}/${file} &> gzip_sw_${file}.wrk

# start the emulation server with a predefined trim length
ssh n869p538@${dut_name} "cd /home/n869p538/wrk_offloadenginesupport/async_nginx_build/nginx_compress_emul; ./start_gzip_emul.sh ${trim_len}"
# perform wrk benchmark
${default_wrk} -t10 -c1024 -H"accept-encoding:gzip, deflate"  -d5  http://${dut}/${file} &> gzip_emul_${file}.wrk
