#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source ${test_dir}/core_utils.sh
source ${test_dir}/perf_utils.sh
source ${test_dir}/plot_utils.sh
source ${test_dir}/debug_utils.sh
source ${test_dir}/remote_utils.sh

export res_dir=${WRK_ROOT}/results

export enc=( "ktls" "https" "axdimm" "qtls" )
#export ev=( "unc_m_cas_count.wr" "unc_m_cas_count.rd" )
export ev=( "unc_m_cas_count.wr" "unc_m_cas_count.rd" )
export cli_cores=( "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" )

#start a quick test
quick_test(){
	enc=$1
	kill_wrkrs
	start_remote_nginx $enc 10
	capture_core_mt_async $1 12 64 10 192.168.1.2 80 file_10G.txt ${1}_band.txt
}

#Start a quick test using variables specified in config file
#Fails if any variables are unset
quick_perf(){
	single_enc_perf https ev 10 64 1 file_4K.txt 1
}

#Get total cycles and construct bar chart comparing encryption methods
#1-duration
ipc_test(){
	[ -z "${1}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	ipc_dir=${res_dir}/ipc_res
	[ ! -d "$ipc_dir" ] && mkdir -p $ipc_dir
	raw_perfs=${ipc_dir}/perfs
	[ ! -d "$raw_perfs" ] && mkdir -p $raw_perfs
	bands=${ipc_dir}/bands
	[ ! -d "$bands" ] && mkdir -p $raw_bands
	raw_bands=${bands}/raw_bands
	[ ! -d "$raw_bands" ] && mkdir -p $raw_bands
	multi_enc_perf enc ev $1 64 cli_cores file_256K.txt $raw_bands $raw_perfs
	num_meths=$( echo "${enc[*]}" | wc -w )
	ipc_dirs=0
	ipc_dirs=( $( ls $raw_perfs --group-directories-first | tr ' ' '\n' | head -n $num_meths | tr ' ' '\n' | awk "{printf(\"${raw_perfs}/%s \",\$0);}" ))
	debug "plotting $num_meths methods: (${ipc_dirs[*]})"
	dir_to_datfrag ipc_dirs ev
	#plot average stats from different directories
}

# call multi_enc_perf with all the methods to compare against
# make a separate dir for each drop rate -- current register size is hardcoded in tofino, will investigate how to modify
# droprate from control plane
# 1- duration
ktls_drop_test(){
	[ -z "${1}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	d_rates=( "0.00" "0.001" "0.01" "0.02" "0.05" )
	ktls_drop_dir=${res_dir}/ktls_drop_res
	[ ! -d "$ktls_drop_dir" ] && mkdir -p $ktls_drop_dir
	dps=${ktls_drop_dir}/data_points
	[ ! -d "$dps" ] && mkdir -p $dps
	raw_perfs=${ktls_drop_dir}/raw_perfs
	[ ! -d "$raw_perfs" ] && mkdir -p $raw_perfs
	raw_bands=${ktls_drop_dir}/raw_bands
	[ ! -d "$raw_bands" ] && mkdir -p $raw_bands
	# separate raw dirs for all rates
	for _d in "${d_rates[@]}"; do
		# remote call to tofino switch
		debug "${FUNCNAME[0]}: Testing Droprate: $_d with $pkts/4096 dropped"
		change_drop $_d
		d_r_b=$raw_bands/${_d}_raw_band
		[ ! -d "$d_r_b" ] && mkdir -p $d_r_b
		d_r_p=$raw_perfs/${_d}_raw_perf
		[ ! -d "$d_r_p" ] && mkdir -p $d_r_p
		d_r_cp=$dps/${_d}_points
		[ ! -d "$d_r_cp" ] && mkdir -p $d_r_cp
		multi_enc_perf enc ev $1 64 cli_cores file_256K.txt $d_r_b $d_r_p $d_r_cp
	done
	get_data_point $dps
	ev+=( "bandwidth" ) # bandwidth is also measured in multi_enc_perf
	ev+=( "latency" ) # bandwidth is also measured in multi_enc_perf
	#dir_to_multibar $dps ev test_dir.tst

}

#extra copy with modified params for regenerating osme results
new_drop(){
	[ -z "${1}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	export enc=( "qtls" )
	d_rates=( "0.1" "1" "2" "5" )
	ktls_drop_dir=${res_dir}/tc_ktls_drop_res
	[ ! -d "$ktls_drop_dir" ] && mkdir -p $ktls_drop_dir
	dps=${ktls_drop_dir}/data_points
	[ ! -d "$dps" ] && mkdir -p $dps
	raw_perfs=${ktls_drop_dir}/raw_perfs
	[ ! -d "$raw_perfs" ] && mkdir -p $raw_perfs
	raw_bands=${ktls_drop_dir}/raw_bands
	[ ! -d "$raw_bands" ] && mkdir -p $raw_bands
	# separate raw dirs for all rates
	for _d in "${d_rates[@]}"; do
		remote_qdisc_drop_rule $_d
		debug "${FUNCNAME[0]}: Testing Droprate: with $_d % droprate"
		d_r_b=$raw_bands/${_d}_raw_band
		[ ! -d "$d_r_b" ] && mkdir -p $d_r_b
		d_r_p=$raw_perfs/${_d}_raw_perf
		[ ! -d "$d_r_p" ] && mkdir -p $d_r_p
		d_r_cp=$dps/${_d}_points
		[ ! -d "$d_r_cp" ] && mkdir -p $d_r_cp
		multi_enc_perf enc ev $1 64 cli_cores file_256K.txt $d_r_b $d_r_p $d_r_cp
		remote_qdisc_remove_rule
	done
	get_data_point $dps
	#ev+=( "bandwidth" ) # bandwidth is also measured in multi_enc_perf
	#dir_to_multibar $dps ev test_dir.tst

}
#extra copy with modified params for regenerating osme results
reorder_test(){
	[ -z "${1}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	export enc=( "ktls" "https" )
	d_rates=( "0.1" "1" "2" "5" )
	ktls_drop_dir=tc_ktls_reorder_res
	[ ! -d "$ktls_drop_dir" ] && mkdir -p $ktls_drop_dir
	dps=${ktls_drop_dir}/data_points
	[ ! -d "$dps" ] && mkdir -p $dps
	raw_perfs=${ktls_drop_dir}/raw_perfs
	[ ! -d "$raw_perfs" ] && mkdir -p $raw_perfs
	raw_bands=${ktls_drop_dir}/raw_bands
	[ ! -d "$raw_bands" ] && mkdir -p $raw_bands
	# separate raw dirs for all rates
	for _d in "${d_rates[@]}"; do
		remote_qdisc_remove_rule
		remote_qdisc_reorder $_d
		debug "${FUNCNAME[0]}: Testing Droprate: with $_d % droprate"
		d_r_b=$raw_bands/${_d}_raw_band
		[ ! -d "$d_r_b" ] && mkdir -p $d_r_b
		d_r_p=$raw_perfs/${_d}_raw_perf
		[ ! -d "$d_r_p" ] && mkdir -p $d_r_p
		d_r_cp=$dps/${_d}_points
		[ ! -d "$d_r_cp" ] && mkdir -p $d_r_cp
		multi_enc_perf enc ev 10 64 cli_cores file_256K.txt $d_r_b $d_r_p $d_r_cp
		remote_qdisc_remove_rule
	done
	get_data_point $dps
	#ev+=( "bandwidth" ) # bandwidth is also measured in multi_enc_perf
	#dir_to_multibar $dps ev test_dir.tst

}

# maximize bandwidth (check what the bandwidth is), sweep server core sizes and compare llc-evictions / memory bandwidth
llc_mem_server_cores(){
	s_cs=( "1" "2" "5" "10" )
	s_c=1
	export enc=( "https" "http" "qtls" "ktls" )
	for s in "${s_cs[@]}"; do
		start_remote_nginx $enc $s_cores
		multi_enc_perf enc ev $1 64 cli_cores file_256K.txt $d_r_b $d_r_p $d_r_cp
	done
}

# use ten cores on server, what is the utilization under each encryption
# scheme
# 1 - duration
percent_cpu_test(){
	export files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_128K.txt" "file_256K.txt")
	#export encs=( "https" "axdimm" "qtls" "ktls" "http" )
	export encs=( "axdimm" )
	cns=64
	tds=1
	s_cores=1

	for file in "${files[@]}"; do
		for enc in "${encs[@]}"; do
			kill_wrkrs
			start_remote_nginx $enc $s_cores
			if [ "$enc" = "http" ]; then 
				capture_core_mt_async https $tds $cns $1 192.168.1.2 80 $file ${enc}_${file}_${1}_${tds}_${cns}_${s_cores}_raw_band
			elif [ "$enc" = "axdimm" ]; then
				capture_core_mt_async axdimm $tds $cns $1 192.168.1.2 443 $file ${enc}_${file}_${1}_${tds}_${cns}_${s_cores}_raw_band
			else
				capture_core_mt_async https $tds $cns $1 192.168.1.2 443 $file ${enc}_${file}_${1}_${tds}_${cns}_${s_cores}_raw_band
			fi
				
			measurements=5
			debug "${FUNCNAME[0]}: starting $enc cpu measurement"
			echo -n "" > ${enc}_${file}_${1}_${tds}_${cns}_${s_cores}_raw_cpu_util
			for i in $( seq 1 $(($measurements )) ); do
				ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'" >> ${enc}_${file}_${1}_${tds}_${cns}_${s_cores}_raw_cpu_util
				sleep $(( $1 / measurements ))
			done
			wait
		done
	done
}

#1-duration
mem_band_core_sweep(){
	#export encs=( "https" "qtls" "ktls" "http" )
	export encs=( "https" "http" )
	export files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_128K.txt" "file_256K.txt")
	export s_cores=( "1" "2" "5" "10" )
	export ev=( "unc_m_cas_count.wr" "unc_m_cas_count.rd" )

	for e in "${encs[@]}"; do
		for f in "${files[@]}"; do
			for s in "${s_cores[@]}"; do
				single_enc_perf $e ev $1 64 12 $f $s
			done
		done
	done
}

#1-duration
llc_core_sweep(){
	[ -z ${encs} ] && export encs=( "https" "http" )
	[ -z ${file} ] && export file="file_36608K.txt"
	[ -z ${s_cores} ] && export s_cores=( "1" "2" "5" "10" )
	[ -z ${c_cores} ] && export c_cores=( "12" )
	[ -z ${ev} ] && export ev=(  "unc_cha_llc_victims.total_e"  "unc_cha_llc_victims.total_f"  "unc_cha_llc_victims.total_m"  "unc_cha_llc_victims.total_s")


	#gen_file_dut $file
	for e in "${encs[@]}"; do
		core_info="nginx_cores,"
		for s in "${s_cores[@]}"; do
			for c in "${c_cores[@]}"; do
				kill_wrkrs
				core_info+="${s}s_${c}x64c,"
				single_enc_perf $e ev $1 $cns $c $file $s
			done
		done
	done
	echo "file_size:${file}" >> res.txt
	echo "Cli_Serv_Config,$core_info" >> res.txt
	total_llc_evict_band >> res.txt
	return

}

#EVICT BAND
llc_multi_file_sweep(){ 
	#export files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_128K.txt" "file_256K.txt")
	#export files=( "file_1M.txt" "file_2M.txt" "file_5M.txt" "file_10M.txt" "file_20M.txt" "file_30M.txt" "file_36608K.txt" )
	#export s_cores=( "3" "4" "6" "7" "8" )
	export encs=( "https" "http" )
	export c_cores=( "1" "2" "5" "10" "12" )
	#export files=( "file_32K.txt" "file_64K.txt" "file_1024K.txt" "file_3600K.txt" "file_36608K.txt" "file_40000K.txt" )
	export files=( "file_10G.txt" )
	export dur=20
	export s_cores=( "1" "2" "5" "10" )
	export ev=(  "unc_cha_llc_victims.total_e"  "unc_cha_llc_victims.total_f"  "unc_cha_llc_victims.total_m"  "unc_cha_llc_victims.total_s" )
	export cns=64

	
	for f in "${files[@]}"; do
		dir=$(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		mkdir $(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		export file=$f
		cd $dir
		llc_core_sweep $dur
		cd ..
	done
}


llc_multi_file_insert_band(){ #INSERT BAND
	#export files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_128K.txt" "file_256K.txt")
	#export files=( "file_1M.txt" "file_2M.txt" "file_5M.txt" "file_10M.txt" "file_20M.txt" "file_30M.txt" "file_36608K.txt" )
	#export s_cores=( "3" "4" "6" "7" "8" )
	export encs=( "https" "http" )
	export c_cores=( "1" "2" "5" "10" "12" )
	export files=( "file_3600K.txt" "file_36608K.txt" "file_40000K.txt" )
	#export files=( "file_10G.txt" )
	export dur=20
	export s_cores=( "1" "2" "5" "10" )
	export ev=(  "llc_misses.pcie_write" "llc_misses.pcie_write" )
	export cns=64

	
	for f in "${files[@]}"; do
		dir=$(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		mkdir $(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		export file=$f
		cd $dir
		llc_core_sweep $dur
		sort_pcie_llc_band >> res.txt
		cd ..
	done
}

mem_multi_file(){ #mem_band
	export encs=( "https" "http" )
	export files=( "file_4K.txt" "file_256K.txt" "file_3600K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K" )
	export dur=10
	export c_cores=( "1" "2" "5" "10" "12" )
	export s_cores=( "1" "2" "5" "10" )
	export ev=(  "unc_m_cas_count.rd"  "unc_m_cas_count.wr" )
	export cns=64

	
	for f in "${files[@]}"; do
		dir=$(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		mkdir $(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		export file=$f
		cd $dir
		llc_core_sweep $dur
		sort_mem_band >> res.txt
		cd ..
	done
}
