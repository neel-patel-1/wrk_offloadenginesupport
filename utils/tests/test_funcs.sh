#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source ${test_dir}/core_utils.sh
source ${test_dir}/perf_utils.sh
source ${test_dir}/plot_utils.sh
source ${test_dir}/debug_utils.sh
source ${test_dir}/remote_utils.sh

export res_dir=${WRK_ROOT}/results

export enc=( "https" "ktlsdrop" )
export ev=( "unc_m_cas_count.wr" "unc_m_cas_count.rd" )
export cli_cores=( "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" )

#start a quick test
quick_test(){
	echo "using default params: (core 1) (10s) (64 connections) dut@(192.168.2.2:80/file_256K.txt)"
	capture_core_block link 1 1 5 192.168.2.2 443 file_256K.txt ktls_band.txt
}

#Start a quick test using variables specified in config file
#Fails if any variables are unset
quick_perf(){
	raw_files=$(pwd)/raw
	perf_dir=$(pwd)/quick_perfs
	mkdir -p $perf_dir
	mkdir -p $raw_files
	perf_outdir_timespec 5 $perf_dir $raw_files/raw_perf.txt ev
	dir_to_datfrag perf_dir ev
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
# make a separate dir for each drop rate
# 1- duration
ktls_drop_test(){
	[ -z "${1}" ] && echo "${FUNCNAME[0]}:Missing Parameters"
	d_rates=( "0.001" "0.01" "0.02" "0.05" )
	ktls_drop_dir=${res_dir}/ktls_drop_res
	[ ! -d "$ktls_drop_dir" ] && mkdir -p $ktls_drop_dir
	dps=${ktls_drop_dir}/perfs
	[ ! -d "$dps" ] && mkdir -p $dps
	raw_perfs=${ktls_drop_dir}/raw_perfs
	[ ! -d "$raw_perfs" ] && mkdir -p $raw_perfs
	raw_bands=${ktls_drop_dir}/raw_bands
	[ ! -d "$raw_bands" ] && mkdir -p $raw_bands
	rate_dirs=()
	# separate raw dirs for all rates
	for _d in "${d_rates[@]}"; do
		# remote call to tofino switch
		#rebuild_drop $_d
		d_r_b=$raw_bands/${_d}_raw_band
		[ ! -d "$d_r_b" ] && mkdir -p $d_r_b
		d_r_p=$raw_perfs/${_d}_raw_perf
		[ ! -d "$d_r_p" ] && mkdir -p $d_r_p
		d_r_cp=$dps/${_d}_perf
		[ ! -d "$d_r_cp" ] && mkdir -p $d_r_cp
		multi_enc_perf enc ev $1 64 cli_cores file_256K.txt $d_r_b $d_r_p $d_r_cp $d_r_cp
		#process bandwidth into currend 
	done
	dir_to_multibar $d_r_cp

}


# PARAMS: 1-# of methods 2-list of methods 3-# of files 4-length of files to test
small_file_test(){
	for i in "${enc[@]}"; do
		#start a bandwidth test
		core	
		capture_core_async
		#start a performance test
		perf_dir

		#combine directory outputs into csv file
	done
}

