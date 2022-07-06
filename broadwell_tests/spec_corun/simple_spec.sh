#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
source ${test_dir}/test_funcs.sh
source ${test_dir}/debug_utils.sh
source ${test_dir}/perf_utils.sh




# 1- test 2-cores to start specs 3-encryption scheme
core_avg(){
	local _cores=$2
	# average rates 
	as=$1_$3_${#_cores[@]}core_spec.rates
	for c in "${_cores[@]}"; do
		echo -n "" > $1_$3_${#_cores[@]}core_spec.rates
		rf=$(grep CSV ${1}_spec_core_${c}.cpu | awk '{print $5}')
		echo $rf
		return
		debug "scp ${remote_host}:${rf} ."
		scp ${remote_host}:${rf} .
		echo $(grep $1 $rf | head -n 1 | awk -F, '{printf("%f,%f\n", $3,$4)}') >> $as
	done
}

process_res(){
	# start remote nginx server
	export enc=( "http" "https" "ktls" "qtls" )
	export tests=(  "523.xalancbmk_r" "525.x264_r" "500.perlbench_r"  "505.mcf_r" )
	cores=( "1" )
	for t in "${tests[@]}"; do
		for i in "${enc[@]}"; do
			core_avg ${t} cores ${i}
		done
		return
	done
}

# start spec benches on individual cores on the remote host
# 1- test 2-cores to start specs 3-additional params to pass to spec
spec_back_cores(){
	debug "${FUNCNAME[0]}: ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1"
	ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1 | tee spec_build.cpu

	local -n _cores=$2
	for c in `seq 1 ${2}`; do
		debug "${FUNCNAME[0]}: ssh ${remote_host} taskset --cpu-list $c ${remote_spec} --iterations=1 --copies=1 $3 -o csv ${1} &"
		2>&1 ssh ${remote_host} "taskset --cpu-list $(( c + 1 )) ${remote_spec} --iterations=1 --copies=1 $3 -o csv ${1}" | tee $1_spec_core_$c.cpu &
	done
	tail -f -n0 $1_spec_core_$c.cpu | grep -qe "Running Benchmarks"
	echo "bench started"
	tail -f -n0 $1_spec_core_$c.cpu | grep  -qe "runcpu finished"
	echo "runcpu_finished"
}

# start spec benches on individual cores on the remote host
# 1- test 2-number of spec cores 3-events 4-system_wide events
spec_back_cores_cli_sampling(){
	debug "${FUNCNAME[0]}: ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1"
	ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1 | tee spec_build.cpu >/dev/null
	for c in `seq 1 $(( $2 - 1 ))`; do
		debug "${FUNCNAME[0]}: 2>&1 ssh ${remote_host} \"taskset --cpu-list $(( c )) ${remote_spec} --iterations=1 --copies=1 $1 -o csv ${1}\" | tee $1_spec_core_$(( c )).cpu &"
		2>&1 ssh ${remote_host} "taskset --cpu-list $(( c )) ${remote_spec} --iterations=1 --copies=1 $1 -o csv ${1}" | tee $1_spec_core_$(( c )).cpu &
	done
	c=$(( $c + 1 ))
	local -n proc_evs=$3
	local -n sys_evs=$4

	p_com="stat "
	[ ! -z "${3}" ] && p_com+="-e $(echo ${proc_evs[*]} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"

	[ ! -z "${4}" ] && s_com="stat --time=10000 "
	[ ! -z "${4}" ] && s_com+="-e $(echo ${sys_evs[*]} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"

	debug "${FUNCNAME[0]}: 2>&1 ssh ${remote_ocperf} ${p_com} ${remote_host} \"taskset --cpu-list $(( c )) ${remote_spec} --iterations=1 --copies=1 $1 -o csv ${1}\" | tee $1_spec_core_$(( c )).cpu &"
	2>&1 ssh ${remote_host} ${remote_ocperf} ${p_com} "taskset --cpu-list $(( c )) ${remote_spec} --iterations=1 --copies=1 $3 -o csv ${1}" | tee $1_spec_core_$(( c )).cpu &
	ctr=1

	#busy wait for bench to start
	debug "${FUNCNAME[0]}:Waiting for benchmark to start"
	while [ "1" ]; do 
		echo -n "."
		if [ ! -z "$( grep -qe "Running Benchmarks" ${1}_spec_core_$(( c )).cpu )" ]; then
			debug "${FUNCNAME[0]}: bench started "
			break
		fi
		sleep 2
	done
	# collect stats during run
	while [ "1" ]; do 
		debug "${FUNCNAME[0]}: sampling cpu util"
		ssh ${remote_host} "taskset --cpu-list 19 top -b -n1 -w512 | grep -e nginx -e $(echo $1 | sed 's/.*\.//g' ) | awk \"\\\$12~/$(echo $1 | sed 's/.*\.//g' )/{spec_sum+=\\\$9; spec_procs+=1;} \\\$12~/nginx*/{nginx_sum+=\\\$9; nginx_procs+=1} END{printf(\\\"spec,%f\\\\nnginx,%f\\\\n\\\", spec_sum/spec_procs, nginx_sum/nginx_procs); }\"" >> cpu_util_breakdown_${ctr}.txt
		debug "${FUNCNAME[0]}: ssh ${remote_host} taskset --cpu-list 19 \"${remote_ocperf} ${s_com} \" 2>sys_wide_stats_${ctr}.txt 1>/dev/null"
		ssh ${remote_host} "taskset --cpu-list 19 ${remote_ocperf} ${s_com} " 2>sys_wide_stats_${ctr}.txt 1>/dev/null
		ctr=$(( $ctr + 1 ))
		if [ ! -z "$( grep -qe "runcpu finished" $1_spec_core_$(( c )).cpu)"  ]; then
			debug "${FUNCNAME[0]}: runcpu completed... removing last (possibly inaccurate) measurements..."
			rm -rf sys_wide_stats_${ctr}.txt cpu_util_breakdown_${ctr}.txt
			break
		fi	
		sleep 30
	done

	#>&2 tail -f -n5 $1_spec_core_$(( c )).cpu | grep -qe "Running Benchmarks"

	#>&2 tail -f -n5 $1_spec_core_$(( c )).cpu  -qe "runcpu finished"
	debug "${FUNCNAME[0]}: bench complete"
}


#1 - enc 2- num cores
nginx_back(){
	kill_nginx
	kill_wrkrs
	start_remote_nginx ${1} ${2}
	capture_core_mt_async ${1} 16 1024 1h ${remote_ip} $( getport ${2} ) file_256K.txt ${1}_file_256K.txt_16_1024_client_${2}_server_band_raw
}

nginx_spec(){
	export encs=( "http" )
	export tests=( "505.mcf_r" "520.omnetpp_r" "531.deepsjeng_r" )
	export c_nums=( "2" )
	export proc_events=(  "l2_rqsts.demand_data_rd_miss" "l2_rqsts.demand_data_rd_hit"  )
	export sys_events=( "unc_m_cas_count.rd" "unc_m_cas_count.wr" "llc_misses.data_read"  )
	kill_wrkrs
	kill_spec
	for enc in "${encs[@]}"; do
		for c in "${c_nums[@]}"; do
			for t in "${tests[@]}"; do
				[ ! -d "${t}_${enc}_${c}_core" ] && mkdir ${t}_${enc}_${c}_core
				cd ${t}_${enc}_${c}_core
				nginx_back $enc $c
				spec_back_cores_cli_sampling ${t} $c proc_events sys_events
				for i in $( grep CSV * | awk '{ print $5 }' ); do scp ${remote_host}:$i .; done
				for i in CPU*; do grep ${t} $i | awk -F, 'NF>7 {print}' | head -n 1; done | awk -F, '{srun+=$3; srate+=$4;}; END {printf("runtime,%f\nrate,%f\n", srun/NR, srate/NR); }' > ${t}_${enc}_${c}_core_stats.txt
				for a in ${proc_events[@]}; do grep $a *.cpu;  done | awk 'NF > 2 && NF <= 5 {for (i=2; i<=NF; i++) {printf("%s,", $i);}; printf("\n");}' | grep -v 'not' > ${t}_${enc}_${c}_core_perf_stats.txt
				cd ../
				kill_wrkrs
				kill_nginx
			done
		done
	done
}



disable_ht
nginx_spec
exit
