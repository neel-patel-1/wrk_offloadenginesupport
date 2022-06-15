#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

source ${test_dir}/data_utils.sh

# generate bar chart for every stat given
# param: 1:- list of directories to generate bar charts comparing data points 2-events 3-output directory for bar charts
dir_to_datfrag(){
	[ -z "${3}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	local -n dirs=${1}
	local -n bar_evs=${2}
	for _bev in "${bar_evs[@]}"; do
		for _dat_dir in "${dirs[@]}"; do
			>&2 echo "${FUNCNAME[0]}: Reading ${_dat_dir}/${_bev}'s"
			points=$(cat $_dat_dir/$_bev*)
			avg=$(average points)
			debug "${FUNCNAME[0]}: ${_dat_dir}'s average of $avg"
			echo $avg
		done
	done
}

# generate bar group for subdir, but generate multiple bar groups (ie.
# multiple subdirs)
# param: 1:- top level directory to generate bar charts comparing data points 2-events 3-output directory for bar group chart
dir_to_multibar(){
	[ -z "${3}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	local -n _multi_evs=$2
	for _multi_dir in ${1}/*; do
		subdirs=()
		subdirs+=("$(ls -d ${_multi_dir}/* )")
		>&2 echo "${FUNCNAME[0]}: Reading ${_multi_dir}"
		dir_to_datfrag subdirs _multi_evs sub_frags.tst #get bar grouping on all
	done

}

# 1-directory 2-stats
get_data_point(){
	cd $1
	groups=( $(ls -d */ | sort -V -t_ -k1) )
	xs=( $(ls -d ${groups[0]}* ) )
	stats=($(ls -d ${xs[0]}*/*))
	headers=()
	for s in "${stats[@]}";do headers+=("$(basename ${s} | sed -E 's/_[0-9]+//g' )"); done
	top_row="$( basename $(dirname $1) )"
	for x in "${xs[@]}"; do top_row+=",$(basename $x)"; done
	for h in "${headers[@]}"; do
		echo $h
		echo $top_row
		for group in "${groups[@]}"; do
			points=( $(ls -d ${group}* ) )
			row=()
			for point in "${points[@]}"; do
				read p < $point/${h}*
				row+=( "$p" )
				#average $point/${stat}*
			done
			echo "$group ${row[@]}" | sed -E -e "s/ /,/g" -e "s/\///g" -e "s/_[a-z]+,/,/"
		done
	done
}
