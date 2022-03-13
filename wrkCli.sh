#!/bin/bash
export OPENSSL_ENGINES=/home/n869p538/ktls_client_server/openssl/openssl/lib/engines-1.1
export LD_LIBRARY_PATH=/home/n869p538/ktls_client_server/openssl/openssl/lib:/home/n869p538/crypto_mb/2020u3/lib:/home/n869p538/intel-ipsec-mb/lib
export LDFLAGS='-L/home/n869p538/intel-ipsec-mb/lib -L/home/n869p538/crypto_mb/2020u3/lib'
#declare -a arr=("128M" "256M" "512M" "1G" "5G" "10G")
declare -a arr=("4K" "16K" "64K" "256K" )

export WRK_ROOT=$(pwd)
export wrk_output=$WRK_ROOT/wrk_files
[ ! -d "$wrk_output" ] && mkdir $wrk_output

for i in "${arr[@]}"
do
	if [ "${1}" = "tlso" ]; then 
		./wrk -t16 -c1024 -e qatengine -d${2}s https://192.168.1.2:443/file_${i}.txt > $wrk_output/offload_${2}_${i}.wrk
	elif [ "${1}" = "tls" ]; then 
		./wrk -t16 -c1024 -d${2}s https://192.168.1.2:443/file_${i}.txt > $wrk_output/tls_${2}_${i}.wrk
	elif [ "${1}" = "tcpsendfile" ]; then
		./wrk -t16 -c1024 -d${2}s http://192.168.1.2:80/file_${i}.txt > $wrk_output/tcpsendfile_${2}_${i}.wrk
	elif [ "${1}" = "tcp" ]; then
		./wrk -t16 -c1024 -d${2}s http://192.168.1.2:80/file_${i}.txt > $wrk_output/tcpsendfile_${2}_${i}.wrk
	else
		./wrk -t16 -c1024 -d${2}s http://192.168.1.2:80/file_${i}.txt > $wrk_output/tcp_${2}_${i}.wrk
	fi
done
