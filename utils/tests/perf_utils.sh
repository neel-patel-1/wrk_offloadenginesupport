#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

source ${test_dir}/parse_utils.sh
source ${test_dir}/core_utils.sh
source ${test_dir}/remote_utils.sh

#### PERF UTILS ###

# Enable remote performance monitoring
perf_enable(){
	2>1 1>/dev/null ssh ${remote_host} sudo ${remote_scripts}/ocperf/enable_events.sh
}

# Start Synchronous system-wide performance monitoring, blocks until remote perf completes
# params: 5:end-variable length list of events to monitor 3-duration 4-outfile 1-remote host and 2-ocperf (1 and 2 should be specified in configuration file)
perfmon_sys(){
	[ -z "${4}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	#[ ! -f "$4" ] && echo -n "" > $4
	perf_enable
	p_com="stat "
	local -n sys_evs=$5
	[ ! -z "${5}" ] && p_com+="-e $(echo ${sys_evs[*]} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"
	debug "${FUNCNAME[0]} Monitoring ${sys_evs[*]}"
	ssh ${1} "${2} ${p_com} sleep $3" 2>$4 1>/dev/null
}

#params: 1-duration 2-outdir 3-perf_filename 4:end-events
#Fails if any variables are unset
perf_outdir_timespec(){
	[ -z "${4}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	source ${WRK_ROOT}/vars/configs.src
	local -n time_evs=$4
	perfmon_sys ${remote_host} ${remote_ocperf} $1 $3 time_evs
	debug "${FUNCNAME[0]}: Moving events (${time_evs[*]}) to directory ($2)"
	[ ! -d "$2" ] && mkdir $2 && debug "${FUNCNAME[0]}: making event dir: (${2})"
	file_to_dir $3 $2 time_evs
}

#params: 1- method array 2-events to test 3-duration 4-clients per core   5-client core list 6-file to fetch 7-wrk output dump dir  8-perf output dump dir
multi_enc_perf(){
	[ -z "${3}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	local -n _multi_methods=$1
	local -n _multi_evs=$2
	local -n _multi_cores=$5
	#start remote nginx
	debug "${FUNCNAME[0]}: testing encryption methods: ${_multi_methods[*]}"
	for _meth in "${_multi_methods[@]}"; do
		start_remote_nginx $_meth $(echo -n "${_multi_cores[*]}" | wc -c )
		if [ "$_meth" = "http" ]; then
			port=80
		else
			port=443
		fi
		wait_time=$(( duration / 6 ))
		perf_time=$(( duration -  duration / 6 ))
		debug "${FUNCNAME[0]}: starting $_meth nginx server..."
		[ ! -d "$8/${_meth}_perf" ] && mkdir $8/${_meth}_perf && debug "${FUNCNAME[0]}: making perf output directory for $_meth"
		capture_cores_async $_meth $4 $3 ${remote_ip} ${port} $6 $7 _multi_cores
		debug "${FUNCNAME[0]}: waiting $wait_time seconds ..."
		sleep $wait_time
		debug "${FUNCNAME[0]}: starting perf capture (${_multi_evs[*]}) ..."
		perf_outdir_timespec ${perf_time} $8/${_meth}_perf $8/${_meth}_raw_perf _multi_evs
	done
}
