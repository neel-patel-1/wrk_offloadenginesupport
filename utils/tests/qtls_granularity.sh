#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

source ${test_dir}/parse_utils.sh
source ${test_dir}/band_utils.sh

export results=${WRK_ROOT}/csv_res/qtls_granularity

for i in "${methods[@]}";do
	#test bandwidth for small file sizes (ie < 25KB) and different numbers of connections and w/ and w/o 
	#reusing connections
	start_band qtls 10
done
