#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

#get perf sleep test func
source ${test_dir}/testutils.sh

#specify output dir
if [ ! -z "$outdir" ];then
	export outdir=${outdir}/${numServerCores}_servercores_${numCores}_clientcores_${fSize}
else
	export outdir=${WRK_ROOT}/csv_res/client_server_perf_analysis/${numServerCores}_servercores_${numCores}_clientcores_${fSize}

fi
[ ! -d $outdir ] && mkdir -p $outdir


>&2 echo "outdir: $outdir"

for method in "${methods[@]}"; do 
	export method
	export perf_dur=$(( $duration - $duration / 6 ))
	export outfile=$outdir/${method}_nginx_perf.csv
	meth_files+=( "$outfile" )
	echo -n "" > $outfile
	export perf_file=$outdir/${numServerCores}_${numCores}_perf
	export band_file=$outdir/${numServerCores}_${numCores}_band
	echo "${method}:${fSize} --- serv:${numServerCores} --- cli:${numCores}"
	[ ! "${numServerCores}" = "n" ] && [ ! "${numCores}" = "n" ] && start_band 
	>&2 echo "band started"
	>&2 echo "warming up file servers $(( $duration - $perf_dur )) seconds..."
	sleep $(( $duration - $perf_dur )) #request file server run for some time
	>&2 echo "measuring events for $perf_dur seconds"
	perfmon #measure syswide events
	kill_procs
	#wait for band_file to populate
	>&2 echo "waiting for bandwidth results"
	while [ -z "$(cat $band_file)" ]; do
		sleep 1
		echo -n "."
	done

	perf_events_row
	>&2 echo "events written"

done

export outfile=$outdir/nginx_all_perf_bands.csv
echo "${numServerCores}_servers_${numCores}_clients_${core_conn}_connections_${fSize},bandwidth(GBit/s),duration,$(echo "${p_events[*]}" | sed 's/ /,/g' )" >> $outfile
for i in "${meth_files[@]}"; do
	cat ${i} >> $outfile
	cat ${i}
done
