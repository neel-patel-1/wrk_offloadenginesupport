#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


kill_wrkrs() {
	ps aux | grep -e "wrk" -e "$duration" | awk '{print $2}' | xargs sudo kill -s 2
}

kill_procs(){
	ssh ${remote_host} ${remote_scripts}/kill_nginx.sh 2>1 1>/dev/null
	ssh ${remote_host} ${remote_scripts}/kill_spec.sh 2>1 1>/dev/null
}

# take "method" "band_file" and "fSize" and write bandwidth achieved to "band_file"
start_band(){
	[ -z "$method" ] && [ -z "$1" ] && echo "no method selected" && exit
	[ -z "$method" ] && method=$1
	[ -z "$duration" ] && echo "no duration selected" && exit
	[ -z "$numServerCores" ] && echo "no server cores selected" && exit
	[ -z "$numCores" ] && echo "no client cores selected" && exit
	[ -z "$band_file" ] && [ -z "$1" ] && echo "no bandwidth output file specified" && exit
	[ -z "$band_file" ] && band_file=$2
	[ -z "$outdir" ] && echo "no output directory specified" && exit
	[ -z "$write_time" ] && export write_time=2
	[ -z "$band_dir" ] && echo "${FUNCNAME[0]}: missing output directory" && exit
	[ ! -d "$outdir" ] && mkdir -p $outdir

	>&2 echo "${FUNCNAME[0]}: starting bandwidth measurement for $method using ($numCores cores x $core_conn connections)"
	2>/dev/null ${band_dir}/maximum_${method}_throughput.sh | tee $band_file &
}

perfmon(){
	2>1 1>/dev/null ssh ${remote_host} sudo ${remote_scripts}/ocperf/enable_events.sh
	p_com="stat -e $(echo ${p_events[*]} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"
	[ ! -d "$outdir" ] && mkdir -p $outdir
	[ -z "$perf_file" ] && perf_file=$outdir/${method}_perf
	#monitor system stats while sleeping
	ssh ${remote_host} ${remote_ocperf} ${p_com} sleep $perf_dur 2>$perf_file 1>/dev/null
}

two_var_app(){ #files should be labeled x_y where x is the horizontal label and y is the vertical label
	[ -z "$outdir" ] && echo "no output directory specified" && exit
	[ -z "$outfile" ] && echo "no outfile specified" && exit
	[ ! -f "$outfile" ] && echo -n "" > $outfile
	[ -z "$horiz" ] && echo "no horizontal axis specified" && exit
	[ -z "$vert" ] && echo "no vertical axis specified" && exit
	[ -z "$append" ] && echo "no file-stat type specified (ie. _band _perf)" && exit

	#create top
	toprow=",$( echo "${horiz[*]}" | sed 's/ /,/g' )"
	echo "" >> $outfile
	[ ! -z "$title" ] && echo "$title" >> $outfile
	echo "$toprow" >> $outfile

	#fill in chart
	for y in "${vert[@]}"; do
		points=( "$y" )
		for x in "${horiz[@]}"; do
			points+=( "$(cat $outdir/${x}_${y}_${append} | grep -Eo '[0-9.][0-9.]*' )" )
		done
		echo "${points[*]}" | sed -e 's/ /,/g' >> $outfile
		points=()
	done
}

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


perf_events_row(){
	# measure perf_events for a specific number of clients and servers
	[ -z "$outdir" ] && echo "no output directory specified" && exit
	[ -z "$outfile" ] && echo "no outfile specified" && exit
	[ ! -f "$outfile" ] && echo -n "" > $outfile
	[ -z "$p_events" ] && echo "no perf events" && exit
	[ -z "${duration}" ] && echo "no duration specified" && exit
	[ -z "$perf_file" ] && perf_file=$outdir/${numServerCores}_${numCores}_perf
	#need separate table for each perf_event
	badname=0 #badname counter
	band=( "$(cat $outdir/${numServerCores}_${numCores}_band | grep -Eo '[0-9.][0-9.]*')" )
	points=( "$method" )
	for p in "${p_events[@]}"; do
		>&2 echo "processing event: $p for method: $method"
		if [ ! -z "$(grep $p $perf_file )" ]; then #grep for the perf event
			points+=( "$(grep $p $perf_file | grep -v "Add" | sed -e"s/,//g" -e "s/$p//g" -e "s/\s\s*//g" )" ) #could find event in file
		else #need user to tell us the name
			pseudo="${name_mismatch[ $badname ]}"
			np=$(grep $pseudo $perf_file |\
				grep -v "Add" | tee $outdir/after_add.txt |\
				sed -e"s/,//g" -e "s/${pseudo}.*//g" \
				-e "s/\s\s*//g" |  tee $outdir/rem_name.txt | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}' |\
				tee $outdir/after_sum.txt )
			points+=( "$np" )
			badname=$(( $badname + 1 ))
		fi
	done
	echo "${method},${duration},${band}$(echo "${points[*]}" | sed -e 's/ /,/g' | sed -e 's/[A-Za-z]*,/,/g' -e 's/[A-Za-z][A-Za-z]*([0-9][0-9]\.[0-9]*%),/,/g' )" >> $outfile
}

two_var_perf(){
	[ -z "$outdir" ] && echo "no output directory specified" && exit
	[ -z "$outfile" ] && echo "no outfile specified" && exit
	[ ! -f "$outfile" ] && echo -n "" > $outfile
	[ -z "$horiz" ] && echo "no horizontal axis specified" && exit
	[ -z "$vert" ] && echo "no vertical axis specified" && exit
	[ -z "$p_events" ] && echo "no perf events" && exit
	#need separate table for each perf_event
	badname=0 #badname counter
	for p in "${p_events[@]}"; do

		echo "" >> $outfile 
		[ ! -z "$title" ] && echo "$title" >> $outfile
		echo "$p" >> $outfile
		inc_bad=n #assume good naming

		#>&2 echo "$p"
		echo ",$(echo "${horiz[*]}" | sed 's/ /,/g' )" >> $outfile
		for y in ${vert[@]}; do
			points=( "$y" )

			for x in ${horiz[@]}; do
				perf_file=$outdir/${x}_${y}_perf

				if [ ! -z "$(grep $p $perf_file )" ]; then #grep for the perf event
					points+=( "$(grep $p $perf_file | grep -v "Add" | sed -e"s/,//g" -e "s/$p//g" -e "s/\s\s*//g" )" ) #could find event in file
				else #need user to tell us the name
					pseudo="${name_mismatch[ $badname ]}"
					np=$(grep $pseudo $perf_file |\
						grep -v "Add" | tee $outdir/after_add.txt |\
						sed -e"s/,//g" -e "s/${pseudo}.*//g" \
						-e "s/\s\s*//g" |  tee $outdir/rem_name.txt | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}' |\
						tee $outdir/after_sum.txt )
					points+=( "$np" )
					inc_bad=y #we need to progress in bad name array
				fi
			done

			echo "${points[*]}" | sed -e 's/ /,/g' >> $outfile
		done
		[ "$inc_bad" = "y" ] && badname=$(( $badname + 1 )) #actually increment bad name counter
	done
}

post_process_table(){
	grep -Eo '([0-9]+)[A-Za-z]+' $outfile | head -n 1
	sed -E 's/\([0-9]+\)[A-Za-z]+,/\1foo/g' $outfile
}

process_pevents(){
	echo "" >> $outfile 
	ev_row=$(echo "stats,$(echo ${p_events[*]} | sed -e 's/ /,/g' )") #row with the events
	[ -z "$pat" ] && pat=$(echo ${methods[@]}|tr " " "|") #user can specify pattern to search for in bandwidth/perf titles
	echo $ev_row >> $outfile
	for g in "${perf_files[@]}"; do  #for each method
		badname=0
		sc=()
		sc+=( "$(echo "$g" | grep -Eo "$pat" ) " ) #label the row
		for p in "${p_events[@]}"; do
			if [ ! -z "$(grep $p $g )" ]; then
				sc+=( "$(grep $p $g | grep -v "Add" | sed -e"s/,//g" -e "s/$p//g" -e "s/\s\s*//g" )" ) #could find event in file
			else #need user to tell us the name
				pseudo="${name_mismatch[ $badname ]}"
				sc+=( "$(grep $pseudo $g |\
					grep -v "Add" |\
					sed -e"s/,//g" -e "s/${pseudo}.*//g"\
					-e "s/\s\s*//g" | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')${mis_append}" )
					badname=$(( $badname + 1 ))
			fi
		done
		echo "$(echo ${sc[*]} | sed -e 's/ /,/g' )" >> $outfile
	done 
	echo "perf events written to $outfile"
}

process_benchmarks(){
	echo "Benchmarks,$(echo ${tests[*]} | sed -e 's/ /,/g' )" >> $outfile
	for f in "${methods[@]}"; do 
		bands=() 
		bands+=("$f") 
		for g in "${tests[@]}"; do  
			bands+=( "$(cat ${g}_${f}_*_band | grep -Eo '[0-9.][0-9.]*') " )
		done
		echo "$(echo ${bands[*]} | sed -e 's/ /,/g' )" >> $outfile
	done

	echo "" >> $outfile
	echo "Rate/Time" >> $outfile
	echo "Benchmarks,$(echo ${tests[*]} | sed -e 's/ /,/g' )" >> $outfile
	for g in "${methods[@]}"; do 
		sc=()
		sc+=("$g")
		for f in "${tests[@]}"; do 
			sc+=( "$(grep -E "$f(_r)?\s\s*[0-9].*" ${f}_${g}_* | head -n 1 | awk '{print $4}')" )
		done 
		echo "$(echo ${sc[*]} | sed -e 's/ /,/g' )" >> $outfile
	done

	echo "" >> $outfile 
	echo "perf" >> $outfile 
	for f in "${tests[@]}"; do #for each benchmark
		echo "$f" >> $outfile
		ev_row=$(echo "stats,$(echo ${p_events[*]} | sed -e 's/ /,/g' )") #row with the events
		echo $ev_row >> $outfile
		for g in "${methods[@]}"; do  #for each method
			badname=0
			sc=()
			sc+=("$g") #label the row
			for p in "${p_events[@]}"; do
				if [ ! -z "$(grep $p ${f}_${g}_*_perf )" ]; then
					sc+=( "$(grep $p ${f}_${g}_*_perf | grep -v "Add" | sed -e"s/,//g" -e "s/$p//g" -e "s/\s\s*//g" )" ) #could find event in file
				else #need user to tell us the name
					pseudo="${name_mismatch[ $badname ]}"
					sc+=( "$(grep $pseudo ${f}_${g}_*_perf |\
						grep -v "Add" |\
						sed -e"s/,//g" -e "s/${pseudo}.*//g"\
						-e "s/\s\s*//g" | awk 'BEGIN{sum=0} {sum+=$1} END{print sum}')${mis_append}" )
						badname=$(( $badname + 1 ))
				fi
			done
			echo "$(echo ${sc[*]} | sed -e 's/ /,/g' )" >> $outfile
		done 
		echo "" >> $outfile #construct a separate table
	done
}

