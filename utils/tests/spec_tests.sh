#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

export prepend="${benchmark_name}"
export outdir=${WRK_ROOT}/spec_res/$prepend
[ ! -d "$outdir" ] && mkdir -p $outdir
export outfile=${WRK_ROOT}/spec_res/$prepend/bench_$(date +%T).csv

copies=1
export fSize=256K
add_params="--nobuild "
export duration=8h #ensure tests background bandwidth endures -- make sure to also change in vars/configs.src

kill_procs(){
	ssh ${remote_host} ${remote_scripts}/kill_nginx.sh
	ssh ${remote_host} ${remote_scripts}/kill_spec.sh
}

kill_wrkrs() {
	ps aux | grep -e "wrk" -e "$duration" | awk '{print $2}' | xargs sudo kill -s 2
}

start_bench(){
	#build the tests
	if [ "$dry_run" = "y" ]; then
		echo "ssh ${remote_host} ${remote_spec} --config=testConfig --action build $t"
	else
		ssh ${remote_host} ${remote_spec} --config=testConfig --action build $t
	fi
	if [ "$separate" = "y" ]; then
		cpu_list=("${sep_cpu_list[@]}")
	else
		cpu_list=("${co_cpu_list[@]}")
	fi

	# load cores with background benchmarks
	for b in `seq 0 $(($(echo "${cpu_list[*]}" | wc -w) - 2))`; do
		if [ "$dry_run" = "y" ]; then
			echo "ssh ${remote_host} ${task_set} ${cpu_list[$b]} ${remote_spec} ${spec_params} &"
		else
			ssh ${remote_host} ${task_set} ${cpu_list[$b]} ${remote_spec} ${spec_params} &
		fi
	done
	# use last core for final benchmark whose results we are interested
	# if there are perf events to calculate, get them here
	if [ ! -z "$p_events" ]; then
		#perf events
		ssh ${remote_host} ${remote_scripts}/ocperf/enable_events.sh
		p_com="stat -e $(echo ${p_events[*]} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"
		if [ "$dry_run" = "y" ]; then
			echo "ssh ${remote_host} ${remote_ocperf} ${p_com} ${task_set} ${cpu_list[$(($(echo "${cpu_list[*]}" | wc -w) - 1))]} ${remote_spec} ${spec_params} 1>spec_out 2>$outdir/${t}_${m}_${cpus}_perf &"
		else
			ssh ${remote_host} ${remote_ocperf} ${p_com} ${task_set} ${cpu_list[$(($(echo "${cpu_list[*]}" | wc -w) - 1))]} ${remote_spec} ${spec_params} 1>spec_out 2>$outdir/${t}_${m}_${cpus}_perf &
		fi
        else
		if [ "$dry_run" = "y" ]; then
			echo "ssh ${remote_host} ${task_set} ${cpu_list[$(($(echo "${cpu_list[*]}" | wc -w) - 1))]} ${remote_spec} ${spec_params} > spec_out &"
		else
			ssh ${remote_host} ${task_set} ${cpu_list[$(($(echo "${cpu_list[*]}" | wc -w) - 1))]} ${remote_spec} ${spec_params} > spec_out &
		fi
	fi

	#export var for output
	cpus="${cpu_list[0]}-${cpu_list[$(($(echo "${cpu_list[*]}" | wc -w) - 1))]}"
	# wait till benchmark started 
	if [ "$dry_run" != "y" ]; then
		tail -f -n0 spec_out | grep -qe "Running Benchmarks"
	fi
}

start_band(){
	# start bandwidth test
	echo "benchmark started -- beginning traffic"
	if [ "$dry_run" = "y" ]; then
		echo "${band_dir}/maximum_${m}_throughput.sh  > $outdir/${t}_${m}_${cpus}_band &"
	else
		${band_dir}/maximum_${m}_throughput.sh  > $outdir/${t}_${m}_${cpus}_band &
	fi
	bPid=$!
}

wait_for_bench(){
	if [ "$dry_run" = "y" ]; then
		echo "tail -f -n0 spec_out | grep  -qe \"runcpu finished\""
	else
		tail -f -n0 spec_out | grep  -qe "runcpu finished"
	fi
	echo "benchmark complete -- killing traffic"
	sudo kill -s 2 $bPid
}

move_res(){
	res_path=$( grep -e 'format: Text' spec_out | awk '{print $4}')
	echo "found results in $res_path"
	scp ${remote_host}:${res_path} $outdir/${t}_${m}_${cpus}

	#delete remote res
	ssh ${remote_host} "rm -rf ${remote_cpu}/result/*"
}

main(){
	for m in "${methods[@]}"; do
		for t in "${tests[@]}"; do
			spec_params="--config=testConfig.cfg  --iterations=1 --copies=$copies ${add_params} -o txt ${t}" # change test
			kill_procs #kills any remote procs
			start_bench #start remote spec cpu instances
			start_band #start worker clients for remtoe nginx server
			wait_for_bench #benchmark completes here stop wrkr proc
			move_res #move results to specified dir
			kill_wrkrs #kill workers
		done
	done
}

main
kill_procs
kill_wrkrs

${spec_utils}/process.sh

rm -f spec_out
