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

#params: 1- method array 2-events to test 3-duration 4-clients per core   5-client core list 6-file to fetch 7-wrk output dump dir(per core)  8-perf output dump dir(method number of files) 9-perf data point dir 
multi_enc_perf(){
	[ -z "${3}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	local -n _multi_methods=$1
	local -n _multi_evs=$2
	local -n _multi_cores=$5
	#start remote nginx
	debug "${FUNCNAME[0]}: testing encryption methods: ${_multi_methods[*]}"
	for _meth in "${_multi_methods[@]}"; do
		if [ "$_meth" = "http" ]; then
			port=80
		else
			port=443
		fi

		wait_time=$(( duration / 6 ))
		perf_time=$(( duration -  duration / 6 ))
		meth_raw_band=$7/${_meth}_raw_band # raw band dump directory for this method
		meth_band_list=${meth_raw_band}/band_list # list of bandwidths
		meth_raw_perf=$8/${_meth}_raw_perf #raw perf file for this method
		meth_data_points=$9/${_meth}_perf #output directory for processed data points
		debug "${FUNCNAME[0]}: outputting raw band to ${meth_raw_band} \n list of bands to ${meth_band_list} \n raw perf file to ${meth_raw_perf} \n data points to ${meth_data_points}"
		
		start_remote_nginx $_meth $(echo -n "${_multi_cores[*]}" | wc -c )
		debug "${FUNCNAME[0]}: starting $_meth nginx server..."

		[ ! -d "${meth_data_points}" ] && mkdir ${meth_data_points} && debug "${FUNCNAME[0]}: making data point output directory for $_meth (${meth_data_points})"
		[ ! -d "${meth_raw_band}" ] && mkdir ${meth_raw_band} && debug "${FUNCNAME[0]}: making wrk output directory for $_meth (${meth_raw_band})"

		capture_cores_async $_meth $4 $3 ${remote_ip} ${port} $6 ${meth_raw_band} _multi_cores
		debug "${FUNCNAME[0]}: waiting $wait_time seconds ..."
		sleep $wait_time
		debug "${FUNCNAME[0]}: starting perf capture (${_multi_evs[*]}) ..."
		perf_outdir_timespec ${perf_time} ${meth_data_points} ${meth_raw_perf} _multi_evs
		# wait for connected capture cores to finish writing (10 seconds)
		for i in `seq 1 10`; do
			wa=0 # we done writing
			for i in ${meth_raw_band}/core_*; do
				[ -z "$(cat $i)" ] \
					&& wa=1 \
					&& echo "${FUNCNAME[0]}: waiting on $i wrk output" #not done
			done
			[ "$wa" = "0" ] && break
			sleep 1
		done
		# parse captured cores
		parse_band_dir ${meth_raw_band} ${meth_raw_band}/${_meth}_band ${meth_raw_band}/${_meth}_summed_band
		gen_nfile "bandwidth" ${meth_data_points} $( cat ${meth_raw_band}/${_meth}_summed_band )


	done
}

#params: 1- method 2-events to test 3-duration 4-clients per core  5-client core list 
# 6-file to fetch 7-wrk output dump dir  8-processed wrk point dest file 
# 9-perf dump dir 10 -processed perf point directory
single_enc_perf(){
	[ -z "${3}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	_meth=$1
	local -n _single_evs=$2
	local -n _single_cores=$5
	debug "${FUNCNAME[0]}: testing encryption method: ${_meth}"

	#start remote nginx
	debug "${FUNCNAME[0]}: starting $_meth nginx server..."
	start_remote_nginx $_meth $(echo -n "${_single_cores[*]}" | wc -c )
	if [ "$_meth" = "http" ]; then
		port=80
	else
		port=443
	fi
	wait_time=$(( duration / 6 ))
	perf_time=$(( duration -  duration / 6 ))
	#start clients
	debug "${FUNCNAME[0]}: starting $_meth clients..."
	capture_cores_async $_meth $4 $3 ${remote_ip} ${port} $6 $7 _single_cores
	debug "${FUNCNAME[0]}: waiting $wait_time seconds ..."
	sleep $wait_time

	# start perf
	debug "${FUNCNAME[0]}: starting perf capture (${_single_evs[*]}) ..."
	perf_outdir_timespec ${perf_time} ${10} ${9}/${_meth}_raw_perf _single_evs

	#process bandwidth into dest_dir
	band=$(parse_band_dir $7 $8)

}

multi_enc_perf_v2(){
	[ -z "${3}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	local -n _multi_methods=$1
	local -n _multi_evs=$2
	local -n _multi_cores=$3
	#start remote nginx
	debug "${FUNCNAME[0]}: testing encryption methods: ${_multi_methods[*]}"
	for _meth in "${_multi_methods[@]}"; do
		single_enc_perf ${_meth} _multi_evs $4 $5 $6 $7 ${9}/${_meth_perf}_perf/bandwidth $9 ${10}/${_meth}_perf
	done
}
