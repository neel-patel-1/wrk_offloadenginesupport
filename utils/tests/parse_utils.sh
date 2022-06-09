#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


# given a "perf_file" and "p_event" (and optional param "search_name" for events whose name differs in perf), extract the event from the file and print it
single_perf_event_single_file(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing params"
	perf_file=$1
	p_event=$2
	[ ! -z "$3" ] && p_event=$3
	>&2 echo "${FUNCNAME[0]}: extracting $2 from $1"
	point=$(grep $p_event $perf_file | grep -v "Add" | awk '{print $1}' | sed -e"s/,//g" -e "s/$p_event//g" -e "s/\s\s*//g" | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}' )
	for p in "${point[@]}"; do
		echo $p
	done
}

# params: 1-input file, 2-output directory 3:end-events
file_to_dir(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing params"
	
	for i in "${@:3}"; do
		stat=$(single_perf_event_single_file $1 $i)
		p_num=$(ls -1 $2/$i* | sort -n | tail -n 1 | grep -Eo '_[0-9]+' | grep -Eo '[0-9]+')
		echo "last p_file: $p_num"
		p_file=$2/${i}_$((p_num + 1))
		if [ -f "${p_file}" ]; then 
			echo "${FUNCNAME[0]}:Error creating file: $p_file"
		fi
		echo $stat > $p_file
	done
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
