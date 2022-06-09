#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

source ${test_dir}/core_utils.sh

## bandwidth test utilities ##

<<wrk_single
	params: 1:method 2:duration 3:output_file 4:num_client_cores 5:connections_per_client_core 6:number of server cores
	optional params 6: extra wrk flags
	Note: Runs in background and writes to output file after duration
wrk_single
wrk_single(){
	[ -z "$5" ] && echo "${funcname[0]}: missing params"
	#todo: replacement functions for maximum scripts should take duration and cli/serv cores as arguments
	>&2 echo "${funcname[0]}: starting bandwidth measurement for $method using ($numcores cores x $core_conn connections)"
	#todo: replace maximum_throughput scripts with functions taking arguments
	2>/dev/null ${band_dir}/maximum_${1}_throughput.sh | tee $3 &
}

<<wrk_nginx
	params: 1:method 2:duration 3:output_file 4:num_client_cores 5:connections_per_client_core 6:number of server cores
	optional params 6: extra wrk flags
	Note: Runs in background and writes to output file after duration
wrk_nginx
wrk_nginx(){
	[ -z "$5" ] && echo "${funcname[0]}: missing params"
	#todo: replacement functions for maximum scripts should take duration and cli/serv cores as arguments
	>&2 echo "${funcname[0]}: starting bandwidth measurement for $method using ($numcores cores x $core_conn connections)"
	#todo: replace maximum_throughput scripts with functions taking arguments
	2>/dev/null ${band_dir}/maximum_${1}_throughput.sh | tee $3 &
}
