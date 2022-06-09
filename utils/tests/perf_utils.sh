#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

source ${test_dir}/parse_utils.sh

#### PERF UTILS ###

# Enable remote performance monitoring
perf_enable(){
	2>1 1>/dev/null ssh ${remote_host} sudo ${remote_scripts}/ocperf/enable_events.sh
}

# Start Synchronous system-wide performance monitoring, blocks until remote perf completes
# params: 5:end-variable length list of events to monitor 3-duration 4-outfile 1-remote host and 2-ocperf (1 and 2 should be specified in configuration file)
perfmon_sys(){
	[ -z "${4}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	perf_enable
	p_com="stat "
	[ ! -z "${5}" ] && p_com+="-e $(echo ${@:5} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"
	ssh ${1} "${2} ${p_com} sleep $3" 2>$4 1>/dev/null
}


#Start a quick test using variables specified in config file
#Fails if any variables are unset
quick_perf(){
	source ${WRK_ROOT}/vars/configs.src
	#events=( "instructions" "LLC-load-misses" "LLC-load-misses" )
	events=( "unc_m_cas_count.wr" "unc_m_cas_count.rd" )
	perfmon_sys ${remote_host} ${remote_ocperf} 5 test_perf.txt "${events[*]}"
	mkdir $(pwd)/test_dir
	file_to_dir test_perf.txt $(pwd)/test_dir "${events[@]}"
}

#params: 1-duration 2-outdir 3-perf_filename 3:end-events
#Fails if any variables are unset
perf_outdir_timespec(){
	source ${WRK_ROOT}/vars/configs.src
	events="${@:3}"
	perfmon_sys ${remote_host} ${remote_ocperf} $1 $2 "${events[*]}"
	[ ! -d "$2" ] && mkdir $2
	file_to_dir test_perf.txt $(pwd)/test_dir "${events[@]}"
}
