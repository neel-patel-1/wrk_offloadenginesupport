#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

source ${test_dir}/remote_utils.sh
source ${test_dir}/testutils.sh
export outdir=${WRK_ROOT}/csv_res/drop_comparisons

export combine_file=$outdir/all_drops.csv
total=4096
drop_files=()
# .1% 1% 2% 5%
drop_rates=( "0.001" "0.01" "0.02" "0.05" ) #out of 4096
for d in "${drop_rates[@]}"; do
	export drop_rate=$d
	d=$(python -c "print (int($d * $total))")
	meth_files=()
	export tablehead="enc_dec_method,duration,fileSize,drop_rate,bandwidth(GBit/s),$(echo "${p_events[*]}" | sed 's/ /,/g' )"
	>&2 rebuild_drop $d
	for method in "${methods[@]}"; do 
		export method
		export perf_dur=$(( $duration - $duration / 6 ))
		export outfile=$outdir/${drop_rate}drop_${method}_nginx_perf.csv
		echo "$tablehead" >> $outfile
		meth_files+=( "$outfile" )
		export perf_file=$outdir/${d}_${method}_${numServerCores}_${numCores}_perf
		export band_file=$outdir/${d}_${method}_${numServerCores}_${numCores}_band
		echo "${method}:${fSize}:${drop_rate} --- serv:${numServerCores} --- cli:${numCores}"

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
		drop_perf_events_row
		>&2 echo "events written"
	done

	export outfile=$outdir/${drop_rate}_nginx_all_perf_bands.csv
	drop_files+=( "$outfile" )
	echo -n "" > $outfile
	echo "$tablehead" >> $outfile
	for i in "${meth_files[@]}"; do
		cat ${i} | tail -n 1 >> $outfile
	done
done

#create single file
echo -n "" > $combine_file
for i in "${drop_files[@]}";do
	cat $i >> $combine_file
done
echo "combined results: $combine_file"
