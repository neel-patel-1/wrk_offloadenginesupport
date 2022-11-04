#!/bin/bash
dut=192.168.1.2

file=rand_file_4K.txt

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source $WRK_ROOT/vars/environment.src

file=rand_file_16K.txt
# start the default server
ssh n869p538@pollux "cd /home/n869p538/wrk_offloadenginesupport/async_nginx_build/nginx_compress_emul; ./start_default_gzip.sh"
# example sw ratio flow
trim_len=$(wget --header="accept-encoding:gzip, deflate" http://192.168.1.2/${file} 2>&1 | grep saved | awk '{print $6}' | sed -e 's/^.//' -e 's/.$//' | xargs du -b | awk '{print $1}')
# perform wrk benchmark
${default_wrk} -t10 -c1024  -d5  http://192.168.1.2/${file} &> gzip_sw_${file}.wrk

# start the emulation server with a predefined trim length
ssh n869p538@pollux "cd /home/n869p538/wrk_offloadenginesupport/async_nginx_build/nginx_compress_emul; ./start_gzip_emul.sh ${trim_len}"
# perform wrk benchmark
${default_wrk} -t10 -c1024  -d5  http://192.168.1.2/${file} &> gzip_emul_${file}.wrk
