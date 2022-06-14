#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

source ${test_dir}/debug_utils.sh

# given a "perf_file" and "p_event" (and optional param "search_name" for events whose name differs in perf), extract the event from the file and print it
single_perf_event_single_file(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing params"
	perf_file=$1
	p_event=$2
	[ ! -z "$3" ] && p_event=$3
	debug "${FUNCNAME[0]}: extracting $2 from $1"
	point=$(grep $p_event $perf_file | grep -v "Add" | awk '{print $1}' | sed -e"s/,//g" -e "s/$p_event//g" -e "s/\s\s*//g" | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}' )
	for p in "${point[@]}"; do
		echo $p
	done
}

# params: 1-input file, 2-output directory 3:end-events
file_to_dir(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing params"
	local -n _f_eves=$3
	for i in "${_f_eves[@]}"; do
		stat=$(single_perf_event_single_file $1 $i)
		p_num=$( ls -1 $2/$i* 2>/dev/null | sort -V | tail -n 1 | grep -Eo '_[0-9]+' | grep -Eo '[0-9]+')
		if [ -z "$p_num" ]; then
			debug "creating new p_file: $i"
			p_file=$2/${i}_0
		else
			debug "${FUNCNAME[0]}:last p_file: $p_num"
			p_file=$2/${i}_$((p_num + 1))
		fi
		if [ -f "${p_file}" ]; then 
			echo "${FUNCNAME[0]}:Error creating file: $p_file" && return -1
		fi
		echo "$stat" > $p_file
	done
}

# 1- target filename 2-target directory #3 stat to insert
gen_nfile(){
	p_num=$( ls -1 $2/$1* 2>/dev/null | sort -V | tail -n 1 | grep -Eo '_[0-9]+' | grep -Eo '[0-9]+')
	# pre-existing band_file check
	if [ -z "$p_num" ]; then
		debug "creating new p_file: ${1}_${p_num}"
		p_file=$2/${1}_0
	else
		debug "${FUNCNAME[0]}:last p_file: ${1}_${p_num}"
		p_file=$2/$1_$((p_num + 1))
	fi
	if [ -f "${p_file}" ]; then 
		echo "${FUNCNAME[0]}:Error creating file: $p_file" && return -1
	fi
	echo "$3" > $p_file
}

# given a bandwidth directory, check each file in the directory and sum the bandwidths and
# get average latencies
# 1- directory 2-core specific outfile
parse_band_dir(){
	[ -z "$3" ] && echo "${FUNCNAME[0]}: missing params" && return -1
	echo -n "" > $2
	total_band=0
	for i in $1/*; do
		band=$(cat $i | sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1 \2/p' <&0)
		echo $band >> $2
		debug "${FUNCNAME[0]}: got $band from $i"
	done
	total=$(awk '$2 ~ /GB/ {sum+=$1*8;} $2 ~ /MB/ {sum+=($1*8)/1000;} END{printf "%.2f %s\n", sum, "GBit/s total"}' ${2})
	debug "${FUNCNAME[0]}: got total bandwidth $total from dir: ${1}"
	echo $( echo "$total" | sed 's/[^0-9.]//g') > $3
}

# 1-raw perf event file 2- per core bandwidth directory 3-output directory
perf_band_lat(){
	file_to_dir $1 $3
	band=$(parse_band_dir $2 ${3}/band)
	gen_nfile "band" $3 $band	
}


#given a (1)name and a (2)perf_file, search the file for names matching the event (as output names may differ from event specified)
find_event_in_file(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: event not found"
	grep $1 $2
}

# given a set of "perf_files" and a "p_event", extract the event from the files in order and 
# create an array containing the stats
perf_row_single_event_mult_files(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing params"
	perf_files=$1
	p_event=$1
	row=()
	for i in "${@:3}"; do	
		row+=( "$(single_perf_event_single_file $1 $2)" )
	done
	echo "${row[*]}" | sed -e 's/ /,/g' >> $outfile
}

