#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


#### PERF UTILS ###

# Enable remote performance monitoring
perf_enable(){
	2>1 1>/dev/null ssh ${remote_host} sudo ${remote_scripts}/ocperf/enable_events.sh
}

# Start Synchronous performance monitoring, blocks until remote perf completes
# params: 1-events to monitor 2-duration 3-outfile (remote host and ocperf specified in configuration file)
perfmon(){
	echo $1 && exit
	perf_enable
	p_com="stat -e $(echo ${p_events[*]} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"
	[ ! -d "$outdir" ] && mkdir -p $outdir
	[ -z "$3" ] && echo "${FUNCNAME[0]}: Missing Parameters"
	# monitor system stats while sleeping
	ssh ${remote_host} ${remote_ocperf} ${p_com} sleep $perf_dur 2>$perf_file 1>/dev/null
}
