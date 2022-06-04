#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


# given a "perf_file" and "p_event" (and optional param "search_name" for events whose name differs in perf), extract the event from the file and print it
single_perf_event_single_file(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing params"
	perf_file=$1
	p_event=$2
	[ ! -z "$3" ] && p_event=$3
	>&2 echo "${FUNCNAME[0]}: extracting $2 (psuedonym:$3) from $1"
	stat=$(grep $pseudo $perf_file |\
		grep -v "Add" |\ 
		sed -e"s/,//g" -e "s/${p_event}.*//g" -e "s/\s\s*//g" |\
	      	awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')
	echo $stat
}

# given a set of "perf_files" and a "p_event", extract the event from the files in order and 
# create an array containing the stats
perf_row_single_event_mult_files(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing params"
	perf_files=$1
	p_events=$2
	row=()
	for i in "${perf_files[@]}"; do	
		row+=( "$(single_perf_event_single_file $1 $2)" )
	done
	echo "${row[*]}" | sed -e 's/ /,/g' >> $outfile
}
