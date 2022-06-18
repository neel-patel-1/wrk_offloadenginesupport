#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
source ${test_dir}/debug_utils.sh

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

# start spec benches on individual cores on the remote host
# 1- test 2-cores to start specs 3-additional params to pass to spec
spec_back_cores(){
	debug "${FUNCNAME[0]}: ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1"
	ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1 | tee spec_build.cpu
	tail -f -n0 spec_build.cpu | grep -qe "Running Benchmarks"

	local -n _cores=$2
	for c in "${_cores[@]}"; do
		debug "${FUNCNAME[0]}: ssh ${remote_host} taskset --cpu-list $c ${remote_spec} --iterations=1 --copies=1 $3 -o csv ${1} &"
		2>&1 ssh ${remote_host} "taskset --cpu-list $c ${remote_spec} --iterations=1 --copies=1 $3 -o csv ${1}" | tee $1_spec_core_$c.cpu &
	done
	tail -f -n0 $1_spec_core_$c.cpu | grep -qe "Running Benchmarks"
	echo "bench started"
	tail -f -n0 $1_spec_core_$c.cpu | grep  -qe "runcpu finished"
	echo "runcpu_finished"
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
	spec_params="--config=testConfig.cfg  --iterations=1 --copies=$copies ${add_params} -o txt ${t}" # change test

	cores=( "1" )
	#spec_back_cores 525.x264_r cores
	spec_back_cores 523.xalancbmk_r cores
	nginx_back_cores cores
}

main
