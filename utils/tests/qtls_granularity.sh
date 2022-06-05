#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

source ${test_dir}/parse_utils.sh
source ${test_dir}/core_utils.sh

export results=${WRK_ROOT}/csv_res/qtls_granularity

#close all connection test
for i in "${methods[@]}";do
	#test bandwidth for small file sizes (ie < 25KB) and different numbers of connections and w/ and w/o 
	#reusing connections
	${i}_core 1 10 10 192.168.2.2 443 file_256K '-H"Connection:Close"'
done
