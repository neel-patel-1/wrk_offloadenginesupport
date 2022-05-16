#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

[ ! -z "$numServerCores" ] && echo "global server cores set in config.src -- cannot vary cores for testing" && exit
[ ! -z "$numCores" ] && echo "global client cores set in config.src -- cannot vary cores for testing" && exit
[ ! -z "$numCores" ] && echo "global duration in config.src -- cannot control duration for testing" && exit

#get perf sleep test func
source ${test_dir}/testutils.sh

#specify output dir
export outdir=${WRK_ROOT}/csv_res/vary_core_nginx
[ ! -d $outdir ] && mkdir -p $outdir
rm -rf $outdir/*

#40 core test
#declare -a serverCoreList=( "1" "5" "10" "20" "40" )
declare -a numCliCores=( "12" "15" "18" )
#declare -a numCliCores=( "1" "5" "10" "20" "40" )
declare -a serverCoreList=( "10" )
export fSize=256K

#axis declarations
declare -a horiz=( ${serverCoreList[*]} )
declare -a vert=( ${numCliCores[*]} )

export perf_dur=10 #how long  to run perf
export duration=10 #how long to make requests to the server
declare -a perf_files=()
declare -a band_files=()
declare -a meth_files=()

#tell helpers the title name and file name to search
export append=band


for method in "${methods[@]}"; do 
	export method
	export outfile=$outdir/${method}_nginx_band_perf.csv
	meth_files+=( "$outfile" )
	echo "" > $outfile
	for s_core in "${serverCoreList[@]}"; do
		for c_core in "${numCliCores[@]}"; do
			export numServerCores=$s_core
			export numCores=$c_core
			export band_file=$outdir/${s_core}_${c_core}_band
			export perf_file=$outdir/${s_core}_${c_core}_perf
			band_files+=( "$band_file" )
			perf_files+=( "$perf_file" )
			echo "${method} --- serv:${numServerCores} --- cli:${numCores}"
			>&2 echo "band started"
			start_band 
			>&2 echo "perf started"
			perfmon #measure syswide events
			kill_procs
			sleep 3 #wait for writers
		done
	done
	export title="$method --- x-axis:server_cores --- y-axis:client_cores"
	>&2 two_var_app
	echo "bandwidth written"
	>&2 two_var_perf
	echo "perf written"
done

export outfile=$outdir/nginx_all_perf_bands.csv
echo "" > $outfile
for i in "${meth_files[@]}"; do
	cat ${i} >> $outfile
done
cat $outfile
