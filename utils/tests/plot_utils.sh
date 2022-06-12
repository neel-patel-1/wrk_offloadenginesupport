#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

source ${test_dir}/data_utils.sh

# param: 1:- list of directories to generate bar charts comparing data points 2-events
dir_to_datfrag(){
	local -n dirs=${1}
	local -n bar_evs=${2}
	for i in "${bar_evs[@]}"; do
		for j in "${dirs[@]}"; do
			>&2 echo "${FUNCNAME[0]}: Reading ${j}}/${i}'s"
			points=$(cat $j/$i*)
			avg=$(average points)
			>&2 echo "${FUNCNAME[0]}: ${i}'s average of $avg"
		done
	done
}
