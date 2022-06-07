#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


#### PERF UTILS ###

# Enable remote performance monitoring
perf_enable(){
	2>1 1>/dev/null ssh ${remote_host} sudo ${remote_scripts}/ocperf/enable_events.sh
}

# Start Synchronous performance monitoring, blocks until remote perf completes
# params: 5:end-variable length list of events to monitor 3-duration 4-outfile 1-remote host and 2-ocperf (1 and 2 should be specified in configuration file)
perfmon(){
	[ -z "${5}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	perf_enable

	p_com="stat -e $(echo ${@:5} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"
	ssh ${1} "${2} ${p_com} sleep $3" 2>$4 1>/dev/null
}


#Start a quick test using variables specified in config file
#Fails if any variables are unset
quick_perf(){
	source ${WRK_ROOT}/vars/configs.src
	perfmon ${remote_host} ${remote_ocperf} 10 test_perf.txt 
}
