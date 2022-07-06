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

# given a bandwidth directory, check each file in the directory and sum the bandwidths
# 1- directory 2-core specific outfile 3-total outfile
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

# given a bandwidth directory, check each file in the directory and get the average latency and highest 99th percent
# 1- directory 2- average latency outfile 3-99th percentile outfile
parse_lat_dir(){
	min=
	max=
	declare -A div=( ["us"]=.000001 ["ms"]=.001 ["m"]=60 ["h"]=3600 )
	for i in $1/*; do
		bandwidth=$(sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1\2/p' $i)
		avg=$(grep Latency $i | awk '{printf("%f", $2);}' )
		echo $avg
		stdev=$(grep Latency $i | awk '{printf("%f", $3);}' )

		units=( $(grep Latency $i | grep -Eo '.s' | head -n 2 | tr '\n' ' ' )) #| sed -e 's/^/"/g' -e 's/ $/"/g' -e 's/ /" "/g' ) )
		echo $units,$stdev,$avg
		break
		conv=$(python -c "print ( $avg * (${div[${units[0]}]#*:} / ${div[${units[1]}]#*:}) )")
		pre=$(python -c "print ($conv + ($stdev * 2.3263))")
		post=$(python -c "print ( $pre * (${div[${units[1]}]#*:} / ${div[${units[0]}]#*:}) )")
		echo $min,$max,$post
		#[[ -z "$min" ] || [ "$post" -lt "$min" ] && min=$post
		#[ -z "$max" ] || [ "$post" -gt "$max" ] && max=$post
	done
	echo $avg
	echo $min
	echo $max
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

parse_cpu_dir(){
	info=0
	for i in *_raw_band; do
		if [ "$(cat $i)" != "" ]; then
			f_size=$( echo $i | awk -F_ '{print $3}' | sed 's/.txt//')
			enc=$(echo $i | awk -F_ '{print $1}')
			postf=$(cat $i | grep -v Ready | grep Transfer | awk "{print \$2 }" | grep -Eo '[A-Za-z]+')

			tot=$(cat $i | grep -v Ready | grep Transfer | awk "{print \$2 * 8}")
			echo $f_size,$enc,$tot$postf
		fi
	done
	for i in *_raw_cpu_util; do
		if [ "$(cat $i)" != "" ]; then
			f_size=$( echo $i | awk -F_ '{print $3}' | sed 's/.txt//')
			enc=$(echo $i | awk -F_ '{print $1}')
			postf=$(cat $i | grep -v Ready | grep Transfer | awk "{print \$2 }" | grep -Eo '[A-Za-z]+')
			tot=$(cat $i | awk 'BEGIN{sum=0;} {sum+=$1} END{avg=sum/NR; print avg}' )
			echo $f_size,$enc,$tot$postf
		fi
	done
}

sort_parse_cpu(){
	parse_cpu_dir | sort -V -t, -k1 -k3| grep -E '(MB|GB)'
	parse_cpu_dir | sort -V -t, -k1 -k3| grep -E '[0-9]$'
}

sort_mem_sweep(){
	export encs=( "https" "qtls" "ktls" "http" )
	export files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_128K.txt" "file_256K.txt")
	export s_cores=( "1" "2" "5" "10" )
	export ev=( "unc_m_cas_count.wr" "unc_m_cas_count.rd" )

	s_labels=",,"
	for i in "${s_cores[@]}"; do
		s_labels+=$i,
		s_labels+=$(echo "${files[*]::${#files[@]}-1}" | sed -E 's/[^ \t]+/,/g') 
	done
	echo $s_labels

	s_labels=,,
	for e in "${encs[@]}"; do
		s_labels+=$(echo "${files[*]}" | sed -E -e 's/ /,/g' -e 's/file_//g' -e 's/\.txt//g' ) 
		s_labels+=,
	done
	s_labels=${s_labels::-1}
	echo $s_labels
	for e in "${encs[@]}"; do
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep unc ))

		for v in "${ev[@]}"; do
			f_help=$v
			enc_row=( "$e" )
			for f in "${files[@]}"; do
				enc_row+=("$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed 's/\./_/g' ))")
				
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep band ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			enc_row+=("$(cat $f)")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done
}

sort_sweep(){
	export encs=( "https"  "http" )
	export files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_128K.txt" "file_256K.txt")
	export s_cores=( "1" "2" "5" "10" )
	export ev=(  "unc_cha_llc_victims.total_e"  "unc_cha_llc_victims.total_f"  "unc_cha_llc_victims.total_m"  "unc_cha_llc_victims.total_s")


	s_labels=",,"
	for i in "${s_cores[@]}"; do
		s_labels+=$i,
		s_labels+=$(echo "${files[*]::${#files[@]}-1}" | sed -E 's/[^ \t]+/,/g') 
	done
	echo $s_labels

	s_labels=,,
	for e in "${encs[@]}"; do
		s_labels+=$(echo "${files[*]}" | sed -E -e 's/ /,/g' -e 's/file_//g' -e 's/\.txt//g' ) 
		s_labels+=,
	done
	s_labels=${s_labels::-1}
	echo $s_labels
	for e in "${encs[@]}"; do

		for v in "${ev[@]}"; do
			f_help=$v
			enc_row=( "$e" )
			files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep $v ))
			for f in "${files[@]}"; do
				enc_row+=("$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed -E 's/[^ \t]+\.//g' ))")
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep band ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			enc_row+=("$(cat $f)")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done
}

# also sum the different llc states and turn MB and GB into just nums
sort_sweep(){
	export encs=( "https"  "http" )
	export files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_128K.txt" "file_256K.txt")
	export s_cores=( "1" "2" "5" "10" )
	export ev=(  "unc_cha_llc_victims.total_e"  "unc_cha_llc_victims.total_f"  "unc_cha_llc_victims.total_m"  "unc_cha_llc_victims.total_s")


	s_labels=",,"
	for i in "${s_cores[@]}"; do
		s_labels+=$i,
		s_labels+=$(echo "${files[*]::${#files[@]}-1}" | sed -E 's/[^ \t]+/,/g') 
	done
	echo $s_labels

	s_labels=,,
	for e in "${encs[@]}"; do
		s_labels+=$(echo "${files[*]}" | sed -E -e 's/ /,/g' -e 's/file_//g' -e 's/\.txt//g' ) 
		s_labels+=,
	done
	s_labels=${s_labels::-1}
	echo $s_labels
	for e in "${encs[@]}"; do

		for v in "${ev[@]}"; do
			f_help=$v
			enc_row=( "$e" )
			files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep $v ))
			for f in "${files[@]}"; do
				enc_row+=("$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed -E 's/[^ \t]+\.//g' ))")
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep band ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			val=$(cat $f)
			mb_p='([0-9][0-9]*\.?[0-9]*)(MB|GB)'
			if [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "MB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 )")
				#echo "MBMATCH:${BASH_REMATCH[1]}"
			else
				val=${BASH_REMATCH[1]}

			fi
			enc_row+=("${val}")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done
}

# also sum the different llc states and turn MB and GB into just nums
sort_sweep_band(){
	[ -z "$encs" ] && export encs=( "https"  "http" )
	[ -z "$files" ] && export files=( "file_36608K.txt" )
	[ -z "$s_cores" ] && export s_cores=( "1" "2" "5" "10" )
	[ -z "$ev" ] && export ev=(  "unc_cha_llc_victims.total_e"  "unc_cha_llc_victims.total_f"  "unc_cha_llc_victims.total_m"  "unc_cha_llc_victims.total_s")
	[ -z "$dur" ] && dur=10


	s_labels=",,"
	for i in "${s_cores[@]}"; do
		s_labels+=$i,
		s_labels+=$(echo "${files[*]::${#files[@]}-1}" | sed -E 's/[^ \t]+/,/g') 
	done
	echo $s_labels

	s_labels=,,
	for e in "${encs[@]}"; do
		s_labels+=$(echo "${files[*]}" | sed -E -e 's/ /,/g' -e 's/file_//g' -e 's/\.txt//g' ) 
		s_labels+=,
	done
	s_labels=${s_labels::-1}
	echo $s_labels
	for e in "${encs[@]}"; do

		for v in "${ev[@]}"; do
			f_help=${v}
			f_help+="_Gbit/s"
			enc_row=( "$e" )
			files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep $v ))
			for f in "${files[@]}"; do
				point=$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed -E 's/[^ \t]+\.//g' ))
				point=$(python -c "print ( $point * 64 * 8 / $dur / 1000000000) ")
				enc_row+=("$point")
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep band ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			val=$(cat $f)
			mb_p='([0-9][0-9]*\.?[0-9]*)(MB|GB)'
			if [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "MB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 )")
				#echo "MBMATCH:${BASH_REMATCH[1]}"
			else
				val=${BASH_REMATCH[1]}

			fi
			enc_row+=("${val}")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done
}

total_llc_evict_band(){
	https_band=https,nginx_bandwidth,$( sort_sweep_band | awk -F, '$1 ~ /band/ { if($2 ~ /https/) for (i=3;i<=NF;i++) sum[i]+=$i} END{for (i in sum) printf("%f,", sum[i]); printf("\n")}' )
	echo "$https_band"
	https_row=https,llc_evict_band,$( sort_sweep_band | awk -F, '$1 ~ /unc_cha_llc.*/ { if($2 ~ /https/) for (i=3;i<=NF;i++) sum[i]+=$i} END{for (i in sum) printf("%f,", sum[i]); printf("\n")}' )
	echo "$https_row"
	http_band=http,nginx_bandwidth,$(sort_sweep_band | awk -F, '$1 ~ /band/ { if($2 ~ /http$/) for (i=3;i<=NF;i++) sum[i]+=$i} END{for (i in sum) printf("%f,", sum[i]); printf("\n")}')
	echo "$http_band"
	http_row=http,llc_evict_band,$(sort_sweep_band | awk -F, '$1 ~ /unc_cha_llc.*/ { if($2 ~ /http$/) for (i=3;i<=NF;i++) sum[i]+=$i} END{for (i in sum) printf("%f,", sum[i]); printf("\n")}')
	echo "$http_row"
}

# also sum the different llc states and turn MB and GB into just nums
sort_pcie_llc_band(){
	[ -z "$encs" ] && export encs=( "https"  "http" )
	[ -z "$files" ] && export files=( "file_3600K.txt" "file_36608K.txt" "file_40000K.txt" )
	[ -z "$s_cores" ] && export s_cores=( "1" "2" "5" "10" )
	[ -z "$ev" ] && export ev=(  "llc_misses.pcie_write" "llc_misses.pcie_write" )
	[ -z "$dur" ] && dur=10


	s_labels=",,"
	for i in "${s_cores[@]}"; do
		s_labels+=$i,
		s_labels+=$(echo "${files[*]::${#files[@]}-1}" | sed -E 's/[^ \t]+/,/g') 
	done
	echo $s_labels

	s_labels=,,
	for e in "${encs[@]}"; do
		s_labels+=$(echo "${files[*]}" | sed -E -e 's/ /,/g' -e 's/file_//g' -e 's/\.txt//g' ) 
		s_labels+=,
	done
	s_labels=${s_labels::-1}
	echo $s_labels
	for e in "${encs[@]}"; do

		for v in "${ev[@]}"; do
			f_help=${v}
			f_help+="_Gbit/s"
			enc_row=( "$e" )
			files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep $v ))
			for f in "${files[@]}"; do
				point=$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed -E 's/[^ \t]+\.//g' ))
				point=$(python -c "print ( $point * 4 * 8 / $dur / 1000000000) ")
				enc_row+=("$point")
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep band ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			val=$(cat $f)
			mb_p='([0-9][0-9]*\.?[0-9]*)(B|KB|MB|GB)'
			if [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "MB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 )")
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "KB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 / 1024 )")
				#echo "MBMATCH:${BASH_REMATCH[1]}"
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "B" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 / 1024 / 1024 )")
			else
				val=${BASH_REMATCH[1]}

			fi
			enc_row+=("${val}")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done
}




sort_mem_band(){
	[ -z "$encs" ] && export encs=( "https"  "http" )
	[ -z "$files" ] && export files=( "file_128K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K" )

	[ -z "$ev" ] && export ev=(  "unc_m_cas_count.rd"  "unc_m_cas_count.wr" )

	[ -z "$dur" ] && dur=20
	[ -z "$perf_time" ] && export perf_time=17

	for e in "${encs[@]}"; do

		for v in "${ev[@]}"; do
			f_help=${v}
			f_help+="_Gbit/s"
			enc_row=( "$e" )
			files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep $v ))
			for f in "${files[@]}"; do
				point=$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed -E 's/[^ \t]+\.//g' ))
				point=$(python -c "print ( $point * 3 * 64 * 8 / $perf_time / 1000000000) ")
				# * CHANS * CACHE_LINE_SIZE * BITS/BYTE / Time / (bits/Gbit)
				enc_row+=("$point")
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep -e 'band$' ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			val=$(cat $f)
			mb_p='([0-9][0-9]*\.?[0-9]*)(B|KB|MB|GB)'
			if [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "MB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 )")
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "KB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 / 1024 )")
				#echo "MBMATCH:${BASH_REMATCH[1]}"
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "B" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1024 / 1024 / 1024 )")
			else
				val=${BASH_REMATCH[1]}

			fi
			enc_row+=("${val}")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done
}

# llc event calc funcs
sort_cache_access(){

	[ -z "$encs" ] && export encs=( "https"  "http" )
	[ -z "$ev" ] && export ev=(  "longest_lat_cache.reference"  "longest_lat_cache.miss" "l2_rqsts.all_demand_data_rd" "l2_rqsts.all_demand_miss" )


	[ -z "$dur" ] && dur=20
	[ -z "$perf_time" ] && export perf_time=17

	for e in "${encs[@]}"; do
		echo "$(basename $(pwd) ),$e"

		for v in "${ev[@]}"; do
			f_help=${v}
			enc_row=( "$e" )
			files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep $v ))
			for f in "${files[@]}"; do
				point=$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed -E 's/[^ \t]+\.//g' ))
				point=$(python -c "print($point)") #convert to a rate
				enc_row+=("$point")
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep -e 'band$' ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			val=$(cat $f)
			mb_p='([0-9][0-9]*\.?[0-9]*)(B|KB|MB|GB)'
			if [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "MB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1000 )")
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "KB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1000 / 1000 )")
				#echo "MBMATCH:${BASH_REMATCH[1]}"
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "B" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} / 1000 / 1000 / 1000 )")
			else
				val=${BASH_REMATCH[1]}

			fi
			enc_row+=("${val}")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done

}


m_c_a(){
	[ -z "$file_dirs" ] && export file_dirs=( "file_128K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K" )
	[ -z "$ev" ] && export ev=(  "longest_lat_cache.reference"  "longest_lat_cache.miss" "l2_rqsts.all_demand_data_rd" "l2_rqsts.all_demand_miss" )
	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		[ ! -d "$file_size" ] && echo "No dir for fsize" && return
		echo $file_size
		debug "entering $file_size"
		cd $( echo $i | grep -Eo '[0-9]+.' )
		sort_cache_access
		cd ..
	done
}

row_to_col(){
	[ -z "$file_dirs" ] && export file_dirs=( "file_128K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K.txt" )
	[ -z "$encs" ] && export encs=( "https"  "http" )
	[ -z "$ev" ] && export ev=(  "longest_lat_cache.reference"  "longest_lat_cache.miss" "l2_rqsts.all_demand_data_rd" "l2_rqsts.all_demand_miss" )
	m_c_a > rows.txt
	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		for enc in "${encs[@]}"; do
			#https://unix.stackexchange.com/questions/169995/rows-to-column-conversion-of-file
			grep -A"$((${#ev[@]} + 1))" -e"${file_size},${enc}\b" rows.txt | awk -F"," 'BEGIN{OFS=","} NR>1{ for (i=1; i<=NF; i++) RtoC[i]= (i in RtoC?RtoC[i] OFS :"") $i; } END{ for (i=1; i<=NF; i++) print RtoC[i] }' > ${file_size}_$enc.all_unsort
			debug "writing ${file_size}_${enc}.all_sort"
			head -n 2 ${file_size}_${enc}.all_unsort  > ${file_size}_${enc}.all_sort
			tail -n +3 ${file_size}_${enc}.all_unsort |  sort -g -k$((${#ev[@]} + 1)) -t, |uniq >> ${file_size}_${enc}.all_sort
		done
	done
}


col_to_gnuplot(){
	[ -z "$dur" ] && dur=10
	[ -z "$file_dirs" ] && export file_dirs=( "file_128K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K.txt" )
	[ -z "$encs" ] && export encs=( "https"  "http" )

	[ -z "$ev" ] && export ev=(  "unc_m_cas_count.rd" "unc_m_cas_count.wr" "llc_misses.data_read" "offcore_response.all_reads.llc_miss.local_dram"  )

	# get rows.txt and colonize
	row_to_col

	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		echo -n "" > ${file_size}_plot.dat
		echo "$pl_min"

		for enc in "${encs[@]}"; do
			debug "generating ${file_size}_plot.dat"
			tail -n +3 ${file_size}_${enc}.all_sort | sed  -e 's/,/ /g' >> ${file_size}_plot.dat
			echo "" >> ${file_size}_plot.dat
			echo "" >> ${file_size}_plot.dat
		done
	done
	# data files complete
	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		ctr=1
		for e in "${ev[@]}"; do # for each (file_size, event) make a new plot
			gp_script="set terminal png size 700,500; set output '${i}_${e}.png';  set datafile separator ' '; set style line 1 linecolor rgb '#0060ad' linetype 1 linewidth 2  pointtype 7 pointsize 1.5; set style line 2 linecolor rgb '#dd181f' linetype 1 linewidth 2 pointtype 5 pointsize 1.5; "
			gp_script+="set yr [0:*]; "
			gp_script+="set title '$(echo "$e" | sed 's/_//g') event vs. encryption'; "
			gp_script+="set xlabel 'Network Bandwidth(Gbit/s)'; "
			gp_script+="set ylabel 'Events/s'; "
			gp_script+="plot '${file_size}_plot.dat' index 0 using $((${#ev[@]}+1)):$ctr title '${encs[0]}' with linespoints linestyle 1 , "
			gp_script+="'${file_size}_plot.dat' index 1 using $((${#ev[@]}+1)):$ctr title '${encs[1]}' with linespoints linestyle 2 "
			debug "making graph for ${i} ${e}"
			gnuplot -e "${gp_script}"
			ctr=$(( ctr + 1))
		done
	done
}

# Gbit/s event plotting functions
sort_cache_access_bit(){

	[ -z "$encs" ] && export encs=( "https"  "http" )
	[ -z "$ev" ] && export ev=(  "longest_lat_cache.reference"  "longest_lat_cache.miss" "l2_rqsts.all_demand_data_rd" "l2_rqsts.all_demand_miss" )


	[ -z "$dur" ] && dur=20
	[ -z "$perf_time" ] && export perf_time=17

	for e in "${encs[@]}"; do
		echo "$(basename $(pwd) ),$e"

		for v in "${ev[@]}"; do
			f_help=${v}
			enc_row=( "$e" )
			files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep $v ))
			for f in "${files[@]}"; do
				point=$( 2>/dev/null single_perf_event_single_file $f $(echo $v | sed -E 's/[^ \t]+\.//g' ))
				if [ "$v" = "llc_misses.data_read" ]; then
					point=$(python -c "print($point * 8 / $dur / 1000000000 )") #convert to a Gbit rate
				else
					point=$(python -c "print($point * 64 * 8 / $dur / 1000000000 )") #convert to a Gbit rate
				fi
				enc_row+=("$point")
			done
			enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
			echo $f_help,$enc_row
		done
		files=($(ls -1 | grep ${e}_ | sort -k7 -k3 -t_ -V | grep -e 'band$' ))
		f_help=band
		enc_row=( "$e" )
		for f in "${files[@]}"; do
			val=$(cat $f)
			mb_p='([0-9][0-9]*\.?[0-9]*)(B|KB|MB|GB)'
			if [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "MB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} * 8 / 1000 )")
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "KB" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} * 8 / 1000 / 1000 )")
				#echo "MBMATCH:${BASH_REMATCH[1]}"
			elif [[ ${val} =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "B" ]] ; then
				val=$(python -c "print(${BASH_REMATCH[1]} * 8 / 1000 / 1000 / 1000 )")
			else
				val=$(python -c "print(${BASH_REMATCH[1]} * 8 )")

			fi
			enc_row+=("${val}")
			
		done
		enc_row=$( echo "${enc_row[*]}" | sed 's/ /,/g')
		echo $f_help,$enc_row
	done

}
m_c_a_bit(){
	[ -z "$file_dirs" ] && export file_dirs=( "file_128K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K" )
	[ -z "$ev" ] && export ev=(  "longest_lat_cache.reference"  "longest_lat_cache.miss" "l2_rqsts.all_demand_data_rd" "l2_rqsts.all_demand_miss" )
	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		[ ! -d "$file_size" ] && echo "No dir for fsize" && return
		echo $file_size
		debug "entering $file_size"
		cd $( echo $i | grep -Eo '[0-9]+.' )
		sort_cache_access_bit
		cd ..
	done
}
row_to_col_bit(){
	[ -z "$file_dirs" ] && export file_dirs=( "file_128K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K.txt" )
	[ -z "$encs" ] && export encs=( "https"  "http" )
	[ -z "$ev" ] && export ev=(  "longest_lat_cache.reference"  "longest_lat_cache.miss" "l2_rqsts.all_demand_data_rd" "l2_rqsts.all_demand_miss" )
	m_c_a_bit > rows.txt
	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		for enc in "${encs[@]}"; do
			#https://unix.stackexchange.com/questions/169995/rows-to-column-conversion-of-file
			grep -A"$((${#ev[@]} + 1))" -e"${file_size},${enc}\b" rows.txt | awk -F"," 'BEGIN{OFS=","} NR>1{ for (i=1; i<=NF; i++) RtoC[i]= (i in RtoC?RtoC[i] OFS :"") $i; } END{ for (i=1; i<=NF; i++) print RtoC[i] }' > ${file_size}_$enc.all_unsort
			debug "writing ${file_size}_${enc}.all_sort"
			head -n 2 ${file_size}_${enc}.all_unsort  > ${file_size}_${enc}.all_sort
			tail -n +3 ${file_size}_${enc}.all_unsort |  sort -g -k$((${#ev[@]} + 1)) -t, |uniq >> ${file_size}_${enc}.all_sort
		done
	done
}
llc_gbit_plot(){
	unset file_dirs
	unset encs
	export file_dirs=( $(ls -d */ | sed 's/\///g') )
	export encs=( "https" )
	export ev=(  "unc_m_cas_count.rd" "unc_m_cas_count.wr" "llc_misses.data_read" "offcore_response.all_reads.llc_miss.local_dram"  )

	# get rows.txt and colonize
	row_to_col_bit

	for i in "${file_dirs[@]}"; do
		debug "${FUNCNAME[0]}: finding encs"; 
		[ -z "${encs}" ] && export encs=( $(ls -1 | awk -F_ '{print $1}' | uniq | grep -v -e'1' -e'res.txt') )
		debug "${FUNCNAME[0]}: using ${encs[*]}"; 
	done
	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		echo -n "" > ${file_size}_plot.dat
		echo "$pl_min"

		for enc in "${encs[@]}"; do
			echo "#${ev[*]}" >> ${file_size}_plot.dat
			debug "generating ${file_size}_plot.dat"
			tail -n +3 ${file_size}_${enc}.all_sort | sed  -e 's/,/ /g' >> ${file_size}_plot.dat
			echo "" >> ${file_size}_plot.dat
			echo "" >> ${file_size}_plot.dat
		done
	done
	# data files complete
	for i in "${file_dirs[@]}"; do
		file_size=$( echo $i | grep -Eo '[0-9]+.' )
		ctr=1
		for e in "${ev[@]}"; do # for each (file_size, event) make a new plot
			gp_script="set terminal png size 700,500; set output '${i}_${e}.png';  set datafile separator ' '; set style line 1 linecolor rgb '#0060ad' linetype 1 linewidth 2  pointtype 7 pointsize 1.5; set style line 2 linecolor rgb '#dd181f' linetype 1 linewidth 2 pointtype 5 pointsize 1.5; "
			gp_script+="set yr [0:*]; "
			gp_script+="set title '$(echo "$e" | sed 's/_//g') Bandwidth from Network Bandwidth -- $file_size File '; "
			gp_script+="set xlabel 'Network Bandwidth (Gbit/s)'; "
			gp_script+="set ylabel 'Memory Bandwidth (Gbit/s)'; "
			gp_script+="plot '${file_size}_plot.dat' index 0 using $((${#ev[@]}+1)):$ctr title '${encs[0]}' with linespoints linestyle 1 , "
			gp_script+="'${file_size}_plot.dat' index 1 using $((${#ev[@]}+1)):$ctr title '${encs[1]}' with linespoints linestyle 2 "
			debug "making graph for ${i} ${e}"
			gnuplot -e "${gp_script}"
			ctr=$(( ctr + 1))
		done
	done
}


# 1- array of MB/GB/B/KB's
sum_band_array(){
	local -n _b_array=$1
	GB=0
	mb_p='([0-9][0-9]*\.?[0-9]*)(B|KB|MB|GB)'
	for i in "${_b_array[@]}"; do
		if [[ $i =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "MB" ]] ; then
			val=$(python -c "print(${BASH_REMATCH[1]} / 1024 )")
		elif [[ $i =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "KB" ]] ; then
			val=$(python -c "print(${BASH_REMATCH[1]} / 1024 / 1024 )")
			#echo "MBMATCH:${BASH_REMATCH[1]}"
		elif [[ $i =~ $mb_p ]] && [[ ${BASH_REMATCH[2]} == "B" ]] ; then
			val=$(python -c "print(${BASH_REMATCH[1]} / 1024 / 1024 / 1024 )")
		else
			val=${BASH_REMATCH[1]}
		fi
		GB=$( python -c "print( $GB + $val )" )
	done
	echo ${GB}
}
