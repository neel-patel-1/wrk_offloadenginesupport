#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

source ${test_dir}/remote_utils.sh
source ${test_dir}/testutils.sh
export outdir=${WRK_ROOT}/csv_res/qtls_granularity_comparisons

export combine_file=$outdir/all.csv

[ ! -z "$core_conn" ] && echo "connection set in config file -- cannot vary for testing" && exit
conns=( "1" "2" "4" "16" "32" ) 
file_sizes=( "4B" "256B" )
for f in "${file_sizes[@]}"; do
	${remote_scripts}/http_gen.sh $f
	for c in "${conns[@]}"; do
		meth_files=()
		export core_conn=$c
		export fSize=$f
		export tablehead="enc_dec_method,duration,fileSize,totalConnections,bandwidth(GBit/s),$(echo "${p_events[*]}" | sed 's/ /,/g' )"
		for method in "${methods[@]}"; do 
			export method
			export perf_dur=$(( $duration - $duration / 6 ))
			export outfile=$outdir/${core_conn}conns_${fSize}fileSize_${method}_nginx_perf.csv
			echo "$tablehead" >> $outfile
			meth_files+=( "$outfile" )
			export perf_file=$outdir/${c}conn_${fsize}filesize_${method}_${numservercores}_${numcores}_perf
			export band_file=$outdir/${c}conn_${fsize}filesize_${method}_${numservercores}_${numcores}_band
			echo "${method}:${fSize}:$c --- serv:${numServerCores} --- cli:${numCores}"

			#do measurements
			[ ! "${numServerCores}" = "n" ] && [ ! "${numCores}" = "n" ] && start_band 
			>&2 echo "band started"
			>&2 echo "warming up file servers $(( $duration - $perf_dur )) seconds..."
			sleep $(( $duration - $perf_dur )) #request file server run for some time
			>&2 echo "measuring events for $perf_dur seconds"
			perfmon #measure syswide events
			kill_procs
			>&2 echo "waiting for bandwidth results"
			while [ -z "$(cat $band_file)" ]; do
				sleep 1
				echo -n "."
			done
			qtls_small_perf_events_row
			>&2 echo "events written"
		done

		export outfile=$outdir/${core_conn}_nginx_all_perf_bands.csv
		drop_files+=( "$outfile" )
		echo -n "" > $outfile
		echo "$tablehead" >> $outfile
		for i in "${meth_files[@]}"; do
			cat ${i} | tail -n 1 >> $outfile
		done
	done
done
#create single file
echo -n "" > $combine_file
for i in "${drop_files[@]}";do
	cat $i >> $combine_file
done
echo "combined results: $combine_file"

