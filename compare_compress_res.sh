#!/bin/bash
source comp_vars.sh

file=rand_file_4K.txt

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source $WRK_ROOT/vars/environment.src

files=( "rand_file_4K.txt" "rand_file_16K.txt" "rand_file_32K.txt" )
#files=( "rand_file_4K.txt" )

for f in "${files[@]}"; do
	file=$f

	# perform wrk benchmark
	echo "gzip_sw_${file}.wrk"
	grep  -e 'Requests/sec' -e 'Transfer/sec' gzip_sw_${file}.wrk

	# perform wrk benchmark
	echo "gzip_emul_${file}.wrk"
	grep  -e 'Requests/sec' -e 'Transfer/sec' gzip_emul_${file}.wrk
done
