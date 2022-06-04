#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

source ${test_dir}/core_utils.sh

## bandwidth test utilities ##

<<start_band
	params: 1:method 2:duration 3:output_file 4:num_client_cores 5:connections_per_client_core
	Note: Runs in background and writes to output file after duration
start_band
start_band(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	#TODO: replacement functions for maximum scripts should take duration and cli/serv cores as arguments
	[ -z "$duration" ] && echo "no duration selected" && exit
	[ -z "$numServerCores" ] && echo "no server cores selected" && exit
	[ -z "$numCores" ] && echo "no client cores selected" && exit

	>&2 echo "${FUNCNAME[0]}: starting bandwidth measurement for $method using ($numCores cores x $core_conn connections)"
	#TODO: replace maximum_throughput scripts with functions taking arguments
	2>/dev/null ${band_dir}/maximum_${1}_throughput.sh | tee $3 &
}
