#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

source ${test_dir}/data_utils.sh

# generate bar chart for every stat given
# param: 1:- list of directories to generate bar charts comparing data points 2-events 3-output directory for bar charts
dir_to_datfrag(){
	local -n dirs=${1}
	local -n bar_evs=${2}
	for _bev in "${bar_evs[@]}"; do
		for _dir in "${dirs[@]}"; do
			>&2 echo "${FUNCNAME[0]}: Reading ${_dir}/${_bev}'s"
			points=$(cat $_dir/$_bev*)
			avg=$(average points)
			debug "${FUNCNAME[0]}: ${_dir}'s average of $avg"
		done
	done
}
