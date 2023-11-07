#!/bin/bash
source comp_vars.sh

file=rand_file_4K.txt

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source $WRK_ROOT/vars/environment.src

files=( "rand_file_4K.txt" "rand_file_16K.txt" "rand_file_32K.txt" )

for f in "${files[@]}"; do
	file=$f
	# start the default server
	ssh n869p538@${dut_name} "cd /home/n869p538/wrk_offloadenginesupport/async_nginx_build/nginx_compress_emul; ./start_default_gzip.sh"
	trim_len=$(wget --header="accept-encoding:gzip, deflate" -O sw_gzip_${file} http://${dut}/${file} 2>&1 | grep saved | awk '{print $6}' | sed -e 's/^.//' -e 's/.$//' | xargs du -b | awk '{print $1}')

	sleep 0.3
	# start the emulation server with a predefined trim length
	ssh n869p538@${dut_name} "cd /home/n869p538/wrk_offloadenginesupport/async_nginx_build/nginx_compress_emul; ./start_gzip_emul.sh ${trim_len}"
	wget --header="accept-encoding:gzip, deflate" -O emul_tzip_$file http://${dut}/${file} 2>&1 
done
