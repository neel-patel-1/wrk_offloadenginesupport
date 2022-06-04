#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
source ${test_dir}/parse_utils.sh
source ${test_dir}/perf_utils.sh

[ -z "$numServerCores" ] && echo "global server cores set in config.src" && exit
[ -z "$numCores" ] && echo "global client cores not set in config.src" && exit

#run one test
export outdir=${WRK_ROOT}/csv_res/band_perf_tables
export fSize=256K

#for every method
for i in "${methods[@]}";
do
	start_band $i $outdir/test_band #get the bandwidth
	perf_mon ${p_events[*]} 10 $outdir/${i}_perf
done
