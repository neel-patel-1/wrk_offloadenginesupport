#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

#param 1-array of points
average(){
	local -n _points=$1
	echo "${_points[@]}" | awk 'BEGIN{sum=0;} {sum+=$1} END{avg=sum/NR; print avg}'
}
