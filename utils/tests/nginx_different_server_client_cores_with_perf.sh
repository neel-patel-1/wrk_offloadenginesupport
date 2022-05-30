#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

[ ! -z "$numServerCores" ] && echo "global server cores set in config.src -- cannot vary cores for testing" && exit
[ ! -z "$numCores" ] && echo "global client cores set in config.src -- cannot vary cores for testing" && exit
[ ! -z "$fSize" ] && echo "global file size set in config.src -- cannot vary sizes for testing" && exit
[ ! -z "$numCores" ] && echo "global duration in config.src -- cannot control duration for testing" && exit

#get perf sleep test func
source ${test_dir}/testutils.sh

#specify output dir
declare -a numCliCores=( "10" )
declare -a serverCoreList=( "10" )
declare -a fSizes=( "4K" "16K" )

export outdir=${WRK_ROOT}/csv_res/multi_cli_core_multi_serv_core
echo $outdir
[ ! -d $outdir ] && mkdir -p $outdir
#rm -rf $outdir/*


export perf_dur=15 #how long  to run perf
export duration=17 #how long to make requests to the server

#tell helpers the title name and file name to search
export append=band

for f_size in "${fSizes[@]}"; do
	for s_core in "${serverCoreList[@]}"; do
		for c_core in "${numCliCores[@]}"; do
			export fSize=$f_size
			export numServerCores=$s_core
			export numCores=$c_core
			${test_dir}/select_client_server_collect_perf.sh
		done
	done
done

export outfile=$outdir/all_cli_serv_cores_with_perfs_and_bands.csv
echo -n "" > $outfile
cd $outdir
for i in $(ls -1 | sort -n -k1 -k3 -k5 -t_); do cat ${i}/nginx_all_perf_bands.csv ; done > $outfile
cat $outfile
echo "outfile in $outfile"

