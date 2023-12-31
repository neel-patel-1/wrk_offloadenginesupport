#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source ${test_dir}/core_utils.sh
source ${test_dir}/perf_utils.sh
source ${test_dir}/parse_utils.sh
source ${test_dir}/plot_utils.sh
source ${test_dir}/debug_utils.sh
source ${test_dir}/remote_utils.sh

export res_dir=${WRK_ROOT}/results

co_run(){
	[ -z "${hw_pref}" ] && hw_pref=y
	[ -z "${enc}" ] && enc=
	[ "${enc}" = "base" ] && enc=
	[ -z "${bench}" ] && bench=mcf_r
	#bench=deepsjeng_r
	[ -z "${shared}" ] && shared=n	
	args=${bench}
	echo "testing ${bench} ..."

	if [ "${hw_pref}" = y ]; then
		ssh ${remote_host} "sudo wrmsr -a 0x1a4 0"
		args+=_with_prefetch
	else
		ssh ${remote_host} "sudo wrmsr -a 0x1a4 15"
		args+=_no_prefetch
	fi

	if [ ! -z "${enc}" ]; then
		start_remote_nginx ${enc} 10
		debug "${FUNC_NAME[0]}:capture_core_mt_async ${enc} 16 1024 8h ${remote_ip} $( getport $enc ) na ${enc}_bench_band.txt"
		sed -i -E "s/UCFile_[0-9]+[A-Z]/UCFile_12345K/g" ${WRK_ROOT}/many_req.lua
		capture_core_mt_async ${enc} 16 1024 8h ${remote_ip} $( getport $enc ) na ${enc}_${hw_pref}_hw_preftch_${bench}_band.txt
		args+=_using_${enc}_nginx
	else
		args+=_using_baseline
	fi
	if [ "${shared}" = n ]; then
		args+=_running_on_different_physical_cores
		ssh ${remote_host} "</dev/null >/dev/null 2>/dev/null ${remote_root}/scripts/spec/10_${bench}.sh sep ${args} && exit "
		#ssh ${remote_host} "</dev/null >/dev/null 2>/dev/null ${remote_root}/scripts/spec/10_deepsjeng_r.sh sep ${args} && exit "
	else
		args+=_running_on_shared_physical_cores
		ssh ${remote_host} "</dev/null >/dev/null 2>/dev/null ${remote_root}/scripts/spec/10_${bench}.sh shared ${args} && exit "
		#ssh ${remote_host} "</dev/null >/dev/null 2>/dev/null ${remote_root}/scripts/spec/10_deepsjeng_r.sh shared ${args} && exit "
	fi
	if [ ! -z "${enc}" ]; then
		kill_wrkrs
	fi
	# fetch the dir to make easier
	scp -r ${remote_host}:${remote_root}/${args} .
}

multi_co_run(){
	encs=( "base" "http" "https" "axdimm" "qtls" "ktls" )
	ssh ${remote_host} "${ROOT_DIR}/scripts/L5P_DRAM_Experiments/setup_cdn_files.sh "
	export hw_pref=n
	export shared=n
	export bench=lbm_r
	for e in "${encs[@]}"; do
		export enc=$e
		co_run 
	done
}

multi_co_run_fixed(){
	export RPS=3000
	#encs=( "base" "https_const" )
	encs=( "ktls_const" )
	export bench=lbm_r
	#encs=( "base" "https_const" )
	#encs=( "https_const" )
	ssh ${remote_host} "${ROOT_DIR}/scripts/L5P_DRAM_Experiments/setup_cdn_files.sh "
	export hw_pref=n
	export shared=y
	for e in "${encs[@]}"; do
		export enc=$e
		co_run 
	done
}

#start a quick test 1-folder name
multi_many_file_test(){
	time=120
	encs=( "http" "https" "axdimm" "qtls" "ktls" )
	# encs=( "qtls" )
	ssh ${remote_host} "sudo wrmsr -a 0x1a4 15"
	mkdir -p ${1}
	cd ${1}
	#sed -i -E "s/\/([A-Za-z]+_)+([0-9]+[A-Za-z])?/UCFile_${1}/g" ${WRK_ROOT}/many_req.lua
	ssh ${remote_host} "${ROOT_DIR}/scripts/L5P_DRAM_Experiments/setup_server.sh ${1} "
	for enc in "${encs[@]}";
	do
		start_remote_nginx $enc 10
		n_tds=$( ssh ${remote_host} ps aux | grep nginx | grep -v grep | awk '{print $2}' | tr -s '\n' ',' | sed 's/,$/\n/' )
		capture_core_mt_async ${enc} 16 1024 ${time} ${remote_ip} $( getport $enc ) na ${enc}_band.txt
		ssh ${remote_host} "sudo rm -rf ${enc}_multi_file.mem; sudo pqos -t ${time} -i1 -I -p \"mbl:[${n_tds}];llc:[${n_tds}];\" -o ${enc}_multi_file.mem " &

		for i in `seq 1 $((time / 2)) `;
		do
			ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$6} END{print sum}'" >> ${enc}_cpu_util
			sleep 1
		done

		wait
		scp ${remote_host}:${enc}_multi_file.mem .

		wait
	done
	cd ..
}

multi_many_file_test_constrps(){
	time=120
	encs=( "https_const" "http_const" "axdimm_const" "qtls_const" "ktls_const" )
	#encs=( "axdimm_const" )
	[ -z "${2}" ] && echo "No RPS specified" && return
	export RPS=${2}
	mkdir -p ${1}
	cd ${1}
	sed -i -E "s/UCFile_[0-9]+[A-Z]/UCFile_${1}/g" ${WRK_ROOT}/many_req.lua
	debug "${FUNCNAME[0]}: ssh ${remote_host} \"${ROOT_DIR}/scripts/L5P_DRAM_Experiments/setup_server.sh ${1} \""
	ssh ${remote_host} "${ROOT_DIR}/scripts/L5P_DRAM_Experiments/setup_server.sh ${1} "
	for enc in "${encs[@]}";
	do
		start_remote_nginx $enc 10
		n_tds=$( ssh ${remote_host} ps aux | grep nginx | grep -v grep | awk '{print $2}' | tr -s '\n' ',' | sed 's/,$/\n/' )
		capture_core_mt_async ${enc} 16 1024 ${time} ${remote_ip} $( getport $enc ) na ${enc}_band.txt
		ssh ${remote_host} "sudo rm -rf ${enc}_multi_file.mem; sudo pqos -t ${time} -i1 -I -p \"mbl:[${n_tds}];llc:[${n_tds}];\" -o ${enc}_multi_file.mem " &

		for i in `seq 1 $((time / 2)) `;
		do
			ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$5} END{print sum}'" >> ${enc}_cpu_util
			sleep 1
		done

		wait
		scp ${remote_host}:${enc}_multi_file.mem .

		wait
	done
	cd ..
}

multi_many_compression_file_const_test(){
	time=120
	encs=( "accel_gzip_const" "http_gzip_const"  "qat_gzip_const" )
	# encs=( "qat_gzip_const"  )
	RPS=${2}
	[ -z "${1}" ] && echo "FSIZE Missing : \$1" && return
	mkdir -p ${1}
	cd ${1}

	sed -i -E "s/UCFile_[0-9]+[A-Z]/UCFile_${1}/g" ${WRK_ROOT}/many_req.lua
	ssh ${remote_host} "${ROOT_DIR}/scripts/L5P_DRAM_Experiments/setup_compression_corpus.sh ${1} "
	for enc in "${encs[@]}";
	do
		if [ ! -f "${enc}*" ]; then
			start_remote_nginx $enc 10
			n_tds=$( ssh ${remote_host} ps aux | grep nginx | grep -v grep | awk '{print $2}' | tr -s '\n' ',' | sed 's/,$/\n/' )
			capture_core_mt_async ${enc} 16 1024 ${time} ${remote_ip} $( getport $enc ) na ${enc}_band.txt
			ssh ${remote_host} "sudo rm -rf ${enc}_multi_file.mem; sudo pqos -t ${time} -i1 -I -p \"mbl:[${n_tds}];llc:[${n_tds}];\" -o ${enc}_multi_file.mem " &

			for i in `seq 1 $((time / 2)) `;
			do
				ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$6} END{print sum}'" >> ${enc}_cpu_util
				sleep 1
			done

			wait
			scp ${remote_host}:${enc}_multi_file.mem .

			wait
		fi
	done
	cd ..
}
multi_many_compression_file_test(){
	time=120
	encs=( "http_gzip"  "qat_gzip" "accel_gzip" )
	#encs=( "qat_gzip" )
	[ -z "${1}" ] && echo "FSIZE Missing : \$1" && return
	mkdir -p ${1}
	cd ${1}

	sed -i -E "s/UCFile_[0-9]+[A-Z]/UCFile_${1}/g" ${WRK_ROOT}/many_req.lua
	ssh ${remote_host} "${ROOT_DIR}/scripts/L5P_DRAM_Experiments/setup_compression_corpus.sh ${1} "
	for enc in "${encs[@]}";
	do
		if [ ! -f "${enc}*" ]; then
			start_remote_nginx $enc 10
			n_tds=$( ssh ${remote_host} ps aux | grep nginx | grep -v grep | awk '{print $2}' | tr -s '\n' ',' | sed 's/,$/\n/' )
			capture_core_mt_async ${enc} 16 1024 ${time} ${remote_ip} $( getport $enc ) na ${enc}_band.txt
			ssh ${remote_host} "sudo rm -rf ${enc}_multi_file.mem; sudo pqos -t ${time} -i1 -I -p \"mbl:[${n_tds}];llc:[${n_tds}];\" -o ${enc}_multi_file.mem " &

			for i in `seq 1 $((time / 2)) `;
			do
				ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$6} END{print sum}'" >> ${enc}_cpu_util
				sleep 1
			done

			wait
			scp ${remote_host}:${enc}_multi_file.mem .

			wait
		fi
	done
	cd ..
}

compress_var_file_sizes(){
	mkdir -p gzip_rps_test
	cd gzip_rps_test
	sizes=( "4K" "16K" )
	for s in "${sizes[@]}"; do
		multi_many_compression_file_test $s
	done

}


compress_var_file_sizes_const(){
	# declare -A sizes=( ["4K"]=77000 )
	# declare -A sizes=( ["1K"]=140000 ["4K"]=77000 )
	mkdir -p gzip_membw_cpu_test
	cd gzip_membw_cpu_test
	declare -A sizes=( ["4K"]=77000 ["16K"]=26000 )
	for i in "${!sizes[@]}"; do
		multi_many_compression_file_const_test ${i} ${sizes[$i]}
	done

}

multi_many_constrps_var_files(){
	# maximum rps found for sw https for a given file size
	# declare -A sizes=( ["1K"]=480000 ["4K"]=480000 \
	# 	                    ["32K"]=180000 ["16K"]=250000 ["64K"]=115000 )

	mkdir -p tls_membw_cpu_test
	cd tls_membw_cpu_test
	declare -A sizes=(  ["4K"]=480000 ["16K"]=250000 )
	for s in "${!sizes[@]}"; do
		multi_many_file_test_constrps $s ${sizes[$s]}
	done

}

multi_many_file_var(){
	# maximum rps found for sw https for a given file size
	# declare -A sizes=( ["1K"]=480000 ["4K"]=480000 \
	# 	                    ["32K"]=180000 ["16K"]=250000 ["64K"]=115000 )
	declare -A sizes=( ["4K"]=480000 ["16K"]=250000 )
	#declare -A sizes=( ["4K"]=480000 )
	mkdir -p tls_rps_test
	cd tls_rps_test
	for s in "${!sizes[@]}"; do
		multi_many_file_test $s
	done

}

quick_test(){
	enc=$1
	[ -z "$2" ] && return	
	if [ -z "$3" ]; then 
		time=10
	else
		time=$3
	fi
	kill_wrkrs
	start_remote_nginx $enc 10
	debug "${FUNCNAME[0]}: capture_core_mt_async $1 10 $2 ${time} ${remote_ip} $( getport $enc ) file_256K.txt ${1}_band.txt"
	capture_core_mt_async $1 10 $2 ${time} ${remote_ip} $( getport $enc ) file_256K.txt ${1}_band.txt
}

quick_file_test(){
	enc=$1
	[ -z "$3" ] && return
	kill_wrkrs
	start_remote_nginx $enc 10
	if [ "$enc" = "http" ]; then
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 1024 10 ${remote_ip} 80 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 4 $2 10 ${remote_ip} 80 ${3} ${1}_band.txt
	else
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 1024 10 ${remote_ip} 443 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 4 $2 10 ${remote_ip} 443 ${3} ${1}_band.txt
	fi
}

emul_nginx_comp(){
	ssh ${remote_host} ${remote_root}/ngx_gzip_comp_cpy/start_default_gzip.sh
	echo "gzip"
	${default_wrk} -t16 -c1024  -d10 -H'accept-encoding:gzip, deflate' http://${remote_ip}:80/rand_file_4K.txt

	echo "emul"
	ssh ${remote_host} ${remote_root}/ngx_gzip_comp_cpy/start_gzip_emul.sh
	${default_wrk} -t16 -c1024  -d10 http://${remote_ip}:80/rand_file_4K.txt
}

#1 - enc
tls_kvs_test(){
	time=1
	enc=${1}
	[ -f "${enc}_kvs.mem" ] && rm -f ${enc}_kvs.mem

	m_tds=$( ssh ${remote_host} ps aux | grep memcached | grep -v grep | awk '{print $2}' | tr -s '\n' ',' | sed 's/,$/\n/' ) 

	${ROOT_DIR}/scripts/tls_memory_antagonist_load.sh

	${ROOT_DIR}/async_nginx_build/scripts/tls_memory_antagonist_fetch_profile.sh $MEM_SIZE &
	pid=$!

	sleep 2
	# while fetching, get memory bandwidth
	rm -f ${enc}_kvs.mem
	while kill -0 $pid 2> /dev/null; do
		ssh ${remote_host} "sudo pqos -t ${time} -i 1 -I -p \"mbl:[${m_tds}];llc:[${m_tds}];\"  " >> ${enc}_kvs.mem # pmon
	done

	wait

}


quick_rdt_comp(){
	enc=$1
	[ -z "$2" ] && return
	s_cores=1
	kill_wrkrs
	start_remote_nginx $enc $s_cores
	if [ "$enc" = "http" ]; then
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 1024 10 ${remote_ip} 80 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 4 $2 10 ${remote_ip} 80 file_256K.txt ${1}_band.txt
	else
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 1024 10 ${remote_ip} 443 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 4 $2 10 ${remote_ip} 443 file_256K.txt ${1}_band.txt
	fi
	wait
	start_remote_nginx ${enc}_rdt ${s_cores}
	if [ "$enc" = "http" ]; then
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 1024 10 ${remote_ip} 80 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 4 $2 10 ${remote_ip} 80 file_256K.txt ${1}_rdt_band.txt
	else
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 1024 10 ${remote_ip} 443 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 4 $2 10 ${remote_ip} 443 file_256K.txt ${1}_rdt_band.txt
	fi
}

#start a quick test
quick_cpu_test(){
	enc=$1
	dur=30
	s_cores=10
	[ -z "$2" ] && return
	kill_wrkrs
	start_remote_nginx $enc $s_cores
	if [ "$enc" = "http" ]; then
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 $2 $dur ${remote_ip} 443 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 12 $2 $dur ${remote_ip} 80 file_256K.txt ${1}_band.txt
	else
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 16 $2 $dur ${remote_ip} 443 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 12 $2 $dur ${remote_ip} 443 file_256K.txt ${1}_band.txt
	fi

	cpu_utils=( )
	for i in `seq 0 $(( dur / 5 )) $(( dur - $(( dur / 5)) ))`; do
		sleep $(( $dur / 5 ))
		debug "${FUNCNAME[0]}: ssh ${remote_host} \"top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'\""
		cpu_utils+=( "$( ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'" )" )
	done
	wait
	file=${1}_${2}con_${dur}sec.out
	echo -n "cpu:" | tee $file
	echo $(average_discard_outliers cpu_utils) | tee -a $file
	echo -n "bandwidth:" | tee -a $file
	echo $(Gbit_from_wrk ${1}_band.txt) | tee -a $file
}

#start a quick test 1-enc 2-cons 3-cli_cores 4-duration
enc_cpu_mem_test(){
	enc=$1
	dur=$4
	s_cores=10
	[ -z "$3" ] && return
	kill_wrkrs
	start_remote_nginx $enc $s_cores
	if [ "$enc" = "http" ]; then
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 $3 $2 $dur ${remote_ip} 443 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 $3 $2 $dur ${remote_ip} 80 file_256K.txt ${1}_band.txt
	else
		debug "${FUNCNAME[0]}: capture_core_mt_async $1 $3 $2 $dur ${remote_ip} 443 file_256K.txt ${1}_band.txt"
		capture_core_mt_async $1 $3 $2 $dur ${remote_ip} 443 file_256K.txt ${1}_band.txt
	fi

	
	debug "${FUNCNAME[0]}: ssh ${remote_host} \"echo '' | sudo tee /home/n869p538/${enc}_${2}.mem\""
	ssh ${remote_host} "echo '' | sudo tee /home/n869p538/${enc}_${2}.mem"

	debug "${FUNCNAME[0]}:ssh ${remote_host} \"sudo pqos -t ${dur} -o ${enc}_${2}.mem -m 'mbl:0-$((s_cores-1));'\""
	ssh ${remote_host} "sudo pqos -t ${dur} -o /home/n869p538/${enc}_${2}.mem -m 'mbl:0-$((s_cores-1));'" &
	cpu_utils=( )
	
	incr=$( echo "$dur / 100" | bc )
	high=$( echo " $dur / 2 " | bc )
	for i in `seq 1 $incr $high`; do
		sleep $incr
		debug "${FUNCNAME[0]}: ssh ${remote_host} \"top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$5} END{print sum}'\""
		cpu_utils+=( "$( ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$5} END{print sum}'" )" )
	done
	wait
	scp ${remote_host}:/home/n869p538/${enc}_${2}.mem ./${enc}_${2}.mem
	avg_cpu=$( average_discard_outliers cpu_utils )
	mem_band=$( band_from_mem ${enc}_${2}.mem )
	band=$( Gbit_from_wrk ${1}_band.txt )
	echo "${avg_cpu[@]}"
	echo "${enc} ${2} ${band} ${avg_cpu} ${mem_band}" | tee ${enc}_${2}_stats.txt
}

# 1-name
enc_multi_test(){
	enc_cpu_mem_test axdimm 
	ats=5
	dur=20
	for i in `seq $ats`; do
		enc_cpu_mem_test axdimm 256 16 20 | grep axdimm | sed "s/^/$(printf '%(%Y-%m-%d--%H:%M:%S)T' -1) /g" | tee -a ${1}_stats.cmb
	done
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
	d_rates=( "2" "5" )
	ktls_drop_dir=tc_ktls_reorder_res_redux
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
		multi_enc_perf enc ev 20 64 cli_cores file_256K.txt $d_r_b $d_r_p $d_r_cp
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


	gen_file_dut $file
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

#need to call single_perf that sums multiple files correct 
llc_con_sweep_mf(){
	[ -z ${encs} ] && export encs=( "https" "http" )
	[ -z ${file} ] && export file="file_36608K.txt"
	[ -z ${s_cores} ] && export s_cores=( "1" )
	[ -z ${c_cores} ] && export c_cores=( "12" )
	[ -z ${cons} ] && export cons=( "2" "4" "16" "32" "64" )
	[ -z ${ev} ] && export ev=(  "unc_cha_llc_victims.total_e"  "unc_cha_llc_victims.total_f"  "unc_cha_llc_victims.total_m"  "unc_cha_llc_victims.total_s")


	gen_file_dut $file
	for e in "${encs[@]}"; do
		core_info="nginx_cores,"
		for s in "${s_cores[@]}"; do
			debug "${FUNCNAME[0]}: starting $s core $e nginx server..."
			start_remote_nginx $e $s
			for c in "${c_cores[@]}"; do
				for con in "${cons[@]}"; do
					kill_wrkrs
					if [ "$con" -lt "$c" ]; then
						single_enc_perf_mf $e ev $1 $con $con $file $s
					else
						single_enc_perf_mf $e ev $1 $con $c $file $s
					fi

					core_info+="${s}s_${c}x${con}c,"
				done
			done
		done
	done
	echo "file_size:${file}" >> res.txt
	echo "Cli_Serv_Config,$core_info" >> res.txt
	total_llc_evict_band >> res.txt
	return

}

#1-duration
llc_con_sweep(){
	[ -z ${encs} ] && export encs=( "https" "http" )
	[ -z ${file} ] && export file="file_36608K.txt"
	[ -z ${s_cores} ] && export s_cores=( "1" )
	[ -z ${c_cores} ] && export c_cores=( "12" )
	[ -z ${cons} ] && export cons=( "2" "4" "16" "32" "64" )
	[ -z ${ev} ] && export ev=(  "unc_cha_llc_victims.total_e"  "unc_cha_llc_victims.total_f"  "unc_cha_llc_victims.total_m"  "unc_cha_llc_victims.total_s")


	gen_file_dut $file
	for e in "${encs[@]}"; do
		core_info="nginx_cores,"
		for s in "${s_cores[@]}"; do
			for c in "${c_cores[@]}"; do
				for con in "${cons[@]}"; do
					kill_wrkrs
					if [ "$con" -lt "$c" ]; then
						single_enc_perf $e ev $1 $con $con $file $s
					else
						single_enc_perf $e ev $1 $con $c $file $s
					fi

					core_info+="${s}s_${c}x${con}c,"
				done
			done
		done
	done

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


#EVICT BAND
cache_access_multi_file_sweep(){ 
	export encs=( "https" "http" )
	export files=( "file_128K.txt" "file_36608K.txt" "file_40000K.txt" "file_50000K.txt" )
	#export files=(  "file_50000K.txt" )
	export dur=20
	export c_cores=( "1" "2" "5" "10" "12" )
	export s_cores=( "1" "2" "5" "10" )
	export ev=(  "l2_lines_in.all" "l2_rqsts.miss" "l2_rqsts.references" )
	export cns=64

	
	for f in "${files[@]}"; do
		dir=$(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		mkdir $(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		export file=$f
		cd $dir
		llc_core_sweep $dur
		sort_cache_access >> res.txt
		cd ..
	done
	col_to_gnuplot
}

file_stat_collect(){ 
	export encs=( "https" )
	export file_dirs=( "file_18304K.txt" "file_1024K.txt" )
	export dur=10
	export c_cores=( "20" )
	export s_cores=( "19" )
	export cons=( "24" "48" "96" "144" "196" "256" "512" "792" "1024" )
	export ev=(  "unc_m_cas_count.rd" "unc_m_cas_count.wr" "llc_misses.data_read" "offcore_response.all_reads.llc_miss.local_dram"  )
	
	for f in "${file_dirs[@]}"; do
		dir=$(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		mkdir $(echo $f | sed -E 's/file_([0-9]+.).txt/\1/g')
		export file=$f
		cd $dir
		llc_con_sweep_mf $dur
		sort_cache_access >> res.txt
		cd ..
	done
	llc_gbit_plot
	#col_to_gnuplot
}

axdimm_multi_serv(){
	export s_cores=( "1" "2" "5" "10" )
	export file_sizes=( "file_64K.txt" "file_256K.txt"  "file_4K.txt" "file_16K.txt" )
	for f_size in "${file_sizes[@]}"; do
		gen_file_dut $f_size
		[ ! -d "$(echo $f_size | sed -E -e 's/B//g' -e 's/file_([0-9]+.).txt/\1/g')" ] && mkdir $(echo $f_size | sed -E -e 's/B//g' -e 's/file_([0-9]+.).txt/\1/g')
		for s in "${s_cores[@]}"; do
			start_remote_nginx axdimm $s
			b_file=axdimm_${s}_12_1024_client_${f_size}_server_band
			capture_core_mt_sync axdimm 12 1024  10 ${remote_ip} 443 ${f_size} $b_file
		done
	done
}

#1- number of clients #2 - number of connections
parallel_ab(){
	gen_file_dut file_256K.txt
	for i in $( seq 1 ${1} ); do
		echo "https://${remote_ip}:443/file_256K.txt" >> URLs.txt
	done
	cat URLs.txt | parallel "ab -c 64 -t 5 {}" > test_ab.out 2>/dev/null
	grep Transfer test_ab.out | awk '{sum+=$3} END {printf("%fGB", (sum / 1024 / 1024)); }' | tee test_ab.band
}

ab_mf_test(){
	export file_dirs=( "36608K" "4K" "16K" "64K" "256K" )
	#file_dirs=( "4K" )
	cons=( "1" "2" "5" "10" "20" "30" "40" "50" "60" "70" "100" "120" "130" "140" "150" "200" "300" "400" "500" "600" "700" "800" "900" "1000" )
	#urlsns=( "2" "5" "10" "20" "30" "40" )
	urlsns=( "40" )

	serv=10
	export ab_events=(  "unc_m_cas_count.rd" "unc_m_cas_count.wr" "llc_misses.data_read" "offcore_response.all_reads.llc_miss.local_dram"  )
	export dur=10

	#genURLs
	for urls in "${urlsns[@]}"; do
		for f in "${file_dirs[@]}"; do
			#nURLs=$(( 1048576 / $( echo $f | grep -Eo '[0-9]+' ) ))
			nURLs=$urls
			[ ! -d "$f" ] && mkdir $f 
			cd $f

			start_remote_nginx https ${serv}

			debug "generating target URLs"
			gen_multi_files_dut $f $nURLs
			echo -n "" > URLs.txt
			for i in $( seq 1 ${nURLs} ); do
				echo "https://${remote_ip}:443/file_${f}.txtf${i}" >> URLs.txt
			done

			for i in "${cons[@]}"; do
				debug "cat URLs.txt | parallel \"ab -c ${i} -t $dur {}\" > https_file_${f}.txt_${nURLs}_${i}_band_raw 2>/dev/null"
				cat URLs.txt | parallel "ab -c ${i} -t $dur {}" > https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band_raw 2>/dev/null &

				perfmon_sys_upd $(( $dur - $dur / 6 )) https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_$( echo "${ab_events[*]}" | sed 's/ /_/g') ab_events
				debug "perfmon_sys_upd $(( $dur - $dur / 6 )) https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_$( echo "${ab_events[*]}" | sed 's/ /_/g') ab_events"

				wait
				grep Transfer https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band_raw | awk '{sum+=$3} END {printf("%fGB", (sum / 1024 / 1024)); }' | tee https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band
				echo ""
				debug "grep Transfer https_file_${f}.txt_${nURLs}_${i}_band_raw | awk '{sum+=$3} END {printf(\"%fGB\", (sum / 1024 / 1024)); }' | tee https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band"
			done
			cd ../
		done
	done
	llc_gbit_plot
}

#1- number of clients #2 - number of connections #3- file size
parallel_ab(){
	gen_file_dut file_$3.txt
	for i in $( seq 1 ${1} ); do
		echo "https://${remote_ip}:443/file_$3.txt" >> URLs.txt
	done
	cat URLs.txt | parallel "ab -c ${2} -t 10 {}" > test_ab.out 2>/dev/null
	grep Transfer test_ab.out | awk '{sum+=$3} END {printf("%fGB", (sum * 8 / 1024 / 1024)); }' | tee test_ab.band
}
ab_mf_test_pt(){
	export file_dirs=( "256K" )
	#file_dirs=( "4K" )
	cons=( "500" )
	urlsns=( "40" )

	serv=10
	export ab_events=(  "unc_m_cas_count.rd" "unc_m_cas_count.wr" "llc_misses.data_read" "offcore_response.all_reads.llc_miss.local_dram"  )
	export dur=10

	#genURLs
	for urls in "${urlsns[@]}"; do
		for f in "${file_dirs[@]}"; do
			#nURLs=$(( 1048576 / $( echo $f | grep -Eo '[0-9]+' ) ))
			nURLs=$urls
			[ ! -d "$f" ] && mkdir $f 
			cd $f

			start_remote_nginx https ${serv}

			debug "generating target URLs"
			gen_multi_files_dut $f $nURLs
			echo -n "" > URLs.txt
			for i in $( seq 1 ${nURLs} ); do
				echo "https://${remote_ip}:443/file_${f}.txtf${i}" >> URLs.txt
			done

			for i in "${cons[@]}"; do
				debug "cat URLs.txt | parallel \"ab -c ${i} -t $dur {}\" > https_file_${f}.txt_${nURLs}_${i}_band_raw 2>/dev/null"
				cat URLs.txt | parallel "ab -c ${i} -t $dur {}" > https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band_raw 2>/dev/null &

				perfmon_sys_upd $(( $dur - $dur / 6 )) https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_$( echo "${ab_events[*]}" | sed 's/ /_/g') ab_events
				debug "perfmon_sys_upd $(( $dur - $dur / 6 )) https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_$( echo "${ab_events[*]}" | sed 's/ /_/g') ab_events"

				wait
				grep Transfer https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band_raw | awk '{sum+=$3} END {printf("%fGB", (sum / 1024 / 1024)); }' | tee https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band
				echo ""
				debug "grep Transfer https_file_${f}.txt_${nURLs}_${i}_band_raw | awk '{sum+=$3} END {printf(\"%fGB\", (sum / 1024 / 1024)); }' | tee https_file_${f}.txt_${nURLs}_${i}_client_${serv}_server_band"
			done
			cd ../
		done
	done
	llc_gbit_plot
}

#1 - enc 2 - file
mbm_test(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing param" && return
	e=$1
	file=$2
	time=30
	start_remote_nginx $e 10
	#con=( "1" "2" "3" "4" "6" "10" "16" "64" "76" "88" "100" "110" "120" "130" "140" "150" "170" "200" "220" "256" "384" "496" "512" "750" "850" "950" "1024" "1148" "1400" "1500" "1600" "1700" "1800" "1900" "2048"  )
	#con=( "1" "2" "4" "8" "16" "32" "64" "128" "256" "512" "1024" "1500" "2048"  )
	#con=(  "16"  "64"  "256" "512" "1024" "1500" )
	con=( "1024" )
	for i in "${con[@]}"; do
		if [ ! -f "${e}_${i}.mem" ]; then
			n_tds=$( ssh ${remote_host} ps aux | grep nginx | grep -v grep | awk '{print $2}' | tr -s '\n' ',' | sed 's/,$/\n/' )
			if [ "${i}" -lt 16 ]; then
				debug "capture_core_mt_async $e ${i} $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt"
				capture_core_mt_async $e ${i} $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt
			else
				debug "capture_core_mt_async $e 16 $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt"
				capture_core_mt_async $e 16 $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt
			fi
			#summing across all cores -- used in 36609 1KB figure
			ssh ${remote_host} "sudo rm -rf ${e}_${i}.mem; sudo pqos -t ${time} -i1 -I -p \"mbl:[${n_tds}];llc:[${n_tds}];\" -o ${e}_${i}.mem " # pmon
			#ssh ${remote_host} "sudo rm -rf ${e}_${i}.mem; sudo pqos -t ${time} -i1 -m \"mbl:[${n_tds}];llc:[${n_tds}];\" -o ${e}_${i}.mem " # cmon
			wait
			scp ${remote_host}:${e}_${i}.mem .
		fi
	done
	
}

mbm_test_cores(){
	[ -z "$2" ] && echo "${FUNCNAME[0]}: missing param" && return
	e=$1
	file=$2
	time=10
	start_remote_nginx $e 10
	#con=( "1" "2" "3" "4" "6" "10" "16" "64" "76" "88" "100" "110" "120" "130" "140" "150" "170" "200" "220" "256" "384" "496" "512" "750" "850" "950" "1024" "1148" "1400" "1500" "1600" "1700" "1800" "1900" "2048"  )
	con=( "1" "2" "4" "8" "16" "32" "64" "128" "256" "512" "1024" "1500" "2048"  )
	#con=(  "1024"   )
	for i in "${con[@]}"; do
		if [ ! -f "${e}_${i}_band.txt" ]; then
			n_tds=$( ssh ${remote_host} ps aux | grep nginx | grep -v grep | awk '{print $2}' | tr -s '\n' ',' | sed 's/,$/\n/' )
			if [ "${i}" -lt 16 ]; then
				debug "capture_core_mt_async $e ${i} $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt"
				capture_core_mt_async $e ${i} $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt
			else
				debug "capture_core_mt_async $e 16 $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt"
				capture_core_mt_async $e 16 $i ${time}  ${remote_ip} $( getport $e ) $file ${e}_${i}_band.txt
			fi
			#summing across all cores -- used in 36609 1KB figure
			ssh ${remote_host} "sudo rm -rf ${e}_${i}.mem; sudo pqos -t ${time} -o ${e}_${i}.mem -m 'mbl:1-10'" # og
			wait
			scp ${remote_host}:${e}_${i}.mem .
		fi
	done
	
}

multi_file_mbm(){
	files=( "file_4K.txt" "file_16K.txt" "file_64K.txt" "file_36608K.txt" "file_256K.txt" )
	encs=( "http" "https" )

	for e in "${encs[@]}"; do
		for f in "${files[@]}"; do
			if [ ! -d "${e}_${f}" ]; then
				mkdir ${e}_${f}
				cd ${e}_${f}
				mbm_test $e $f 
				cd ../
			fi
		done
	done

}

# 1 - encs
comp_configs(){

	enc=$1
	con=( "1" "2" "3" "4" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 1 10 | tee -a ${enc}_${c}.txt
		fi
	done
	con=( "4" "16" "64" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 4 10 | tee -a ${enc}_${c}.txt
		fi
	done
	con=( "76" "88" "100" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 4 10 | tee -a ${enc}_${c}.txt
		fi
	done
	con=( "140" "150" "170" "200" "220" "256" "384" "496" "512" "750" "850" "950" "1024" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 16 10 | tee -a ${enc}_${c}.txt
		fi
	done
	con=( "1148" "1400" "1500" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 16 10 | tee -a ${enc}_${c}.txt
		fi
	done

}
# 1 - encs
comp_configs_short(){

	enc=$1
	con=(  "2"   )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 1 10 | tee -a ${enc}_${c}.txt
		fi
	done
	con=( "4" "16" "64" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 4 10 | tee -a ${enc}_${c}.txt
		fi
	done
	con=(   "256"  "512"  "1024" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 16 10 | tee -a ${enc}_${c}.txt
		fi
	done
	con=( "1500" )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 16 10 | tee -a ${enc}_${c}.txt
		fi
	done

}

# 1 - encs
comp_configs_single(){

	enc=$1
	con=(  "256"  )
	for c in "${con[@]}"; do
		if [ ! -f "${enc}_${c}.txt" ]; then
			enc_cpu_mem_test $enc $c 16 120 | tee -a ${enc}_${c}.txt
		fi
	done
}

axdimm_flush_sweep(){
	#ratios=( "0" "5" "20" "50" "75" "80" "90" "91" "93" "95" "100"  )
	#ratios=( "5" "100" "20" "50"  "62" "75" "90"   )
	#ratios=( "5" "20" "50" "100" )
	ratios=( "50" "100"  )
	for i in "${ratios[@]}"; do
		if [ ! -d "SmartDIMM_flush_${i}_of_100" ]; then
			mkdir -p SmartDIMM_flush_${i}_of_100
			cd SmartDIMM_flush_${i}_of_100
			ssh ${remote_host} "sed -i -E 's/#define fl_ratio [0-9]+/#define fl_ratio $i/g' $remote_axdimm_sw"
			ssh ${remote_host} "${remote_scripts}/axdimm/bo.sh"
			comp_configs_single axdimm
		cd ..
		fi
	done

}

https_band_assoc(){
	comp_configs_short https
}

toggle_confs_axdimm(){
	remote_axdimm_confs
	return
	#confs=( "MEM_BAR" "CPY_SERVER" "ORDERED_WRITES" "LAZY_FREE" "CACHE_FLUSH" "PREF_CFG_DAT" "CONF_KEY" "MMAP_UNCACHE" )
	confs=( "MEM_BAR" "CPY_SERVER" "ORDERED_WRITES" "LAZY_FREE" "PREF_CFG_DAT" "CONF_KEY" )
	for c in "${confs[@]}"; do
		[ ! -d "SmartDIMM_WITHOUT_$c" ] && mkdir SmartDIMM_WITHOUT_$c
		cd SmartDIMM_WITHOUT_$c
		CONFIGS=""
		for ins in "${confs[@]}"; do
			[ "$ins" != "$c" ] && CONFIGS+="# define $ins\\n"
		done

		ssh ${remote_host} "sed -i '/\\/\\/BASELINE_BEG/,/\\/\\/BASELINE_END/c\\//BASELINE_BEG\\n${CONFIGS}//BASELINE_END' $remote_axdimm_sw"
		ssh ${remote_host} "${remote_scripts}/axdimm/qat_recomp_install.sh"
		comp_configs_single axdimm
		cd ..
	done
	[ ! -d "SmartDIMM_BASELINE" ] && mkdir SmartDIMM_BASELINE
	cd SmartDIMM_BASELINE
	CONFIGS=""
	for ins in "${confs[@]}"; do
		CONFIGS+="# define $ins\\n"
	done
	ssh ${remote_host} "sed -i '/\\/\\/BASELINE_BEG/,/\\/\\/BASELINE_END/c\\//BASELINE_BEG\\n${CONFIGS}//BASELINE_END' $remote_axdimm_sw"
	ssh ${remote_host} "${remote_scripts}/axdimm/qat_recomp_install.sh"
	comp_configs_single axdimm
	cd ..
}

enc_comp(){
	export encs=( "https" "axdimm"  "ktls" "http" )
	for enc in "${encs[@]}"; do
		mkdir $enc
		cd $enc
		comp_configs_single $enc
		cd ..
	done
}


# 1 - dur
axdimm_iperf(){
	dur=$1
	flags=$2
	[ ! -f "${iperf_dir}/newreq.pem" ] || [ ! -f "${iperf_dir}/key.pem" ] && openssl req -x509 -newkey rsa:2048 -keyout ${iperf_dir}/key.pem -out ${iperf_dir}/newreq.pem -days 365 -nodes
	cd ${iperf_dir}

	>&2 echo "[info] AXDIMM iperf client..."
	sudo env \
	OPENSSL_ENGINES=$AXDIMM_ENGINES \
	LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_DIR/lib \
	$offload_iperf --tls=qat -c ${remote_ip} -t $dur -i 5 ${flags} &
}

# 1 - dur
tls_iperf(){
	dur=$1
	flags=$2
	[ ! -f "${iperf_dir}/newreq.pem" ] || [ ! -f "${iperf_dir}/key.pem" ] && openssl req -x509 -newkey rsa:2048 -keyout ${iperf_dir}/key.pem -out ${iperf_dir}/newreq.pem -days 365 -nodes
	cd ${iperf_dir}

	>&2 echo "[info] TLS iperf client..."
	sudo env \
	LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f \
	$offload_iperf --tls=v1.2 -c ${remote_ip} -t $dur -i 5 ${flags} &
}

# 1 - dur
ktls_iperf(){
	ktls_iperf=/home/n869p538/wrk_offloadenginesupport/client_wrks/autonomous-asplos21-artifact/iperf/src/iperf
	dur=$1
	flags=$2
	[ ! -f "${iperf_dir}/newreq.pem" ] || [ ! -f "${iperf_dir}/key.pem" ] && openssl req -x509 -newkey rsa:2048 -keyout ${iperf_dir}/key.pem -out ${iperf_dir}/newreq.pem -days 365 -nodes
	cd ${iperf_dir}

	>&2 echo "[info] KTLS iperf client..."
	sudo env \
	LD_LIBRARY_PATH=/home/n869p538/wrk_offloadenginesupport/client_wrks/autonomous-asplos21-artifact/openssl:$LD_LIBRARY_PATH \
	$ktls_iperf -c ${remote_ip} -t $dur -i 5 -l262144 --tls --ktls --ktls_record_size=16000 &
}

# 1 - dur
qtls_iperf(){
	qtls_iperf=/home/n869p538/wrk_offloadenginesupport/async_nginx_build/iperf_test/iperf_ssl/src/iperf
	dur=$1
	flags=$2
	[ ! -f "${iperf_dir}/newreq.pem" ] || [ ! -f "${iperf_dir}/key.pem" ] && openssl req -x509 -newkey rsa:2048 -keyout ${iperf_dir}/key.pem -out ${iperf_dir}/newreq.pem -days 365 -nodes
	cd ${iperf_dir}

	>&2 echo "[info] QTLS iperf client..."
	sudo env \
	LD_LIBRARY_PATH=/home/n869p538/wrk_offloadenginesupport/client_wrks/autonomous-asplos21-artifact/openssl:$LD_LIBRARY_PATH \
	$qtls_iperf -c localhost -t $dur -i 5 -l262144 --tls --ktls --ktls_record_size=16000 &
}

# 1 - dur
tcp_iperf(){
	dur=$1
	flags=$2
	cd ${iperf_dir}
	>&2 echo "[info] TCP iperf client..."
	sudo env \
	LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f \
	$offload_iperf -c ${remote_ip} -t $dur -i 5 ${flags} &
}

iperf_cli(){
	[ -z "$2" ] && debug "${FUNCNAME[0]}: Missing params"
	enc=$1
	dur=$2
	${1}_iperf $2 $3 > ${enc}_${dur}.iperf
	debug "${FUNCNAME[0]}:ssh ${remote_host} \"sudo pqos -t ${dur} -o ${enc}_${2}.mem -m 'mbl:1-20;'\""
	ssh ${remote_host} "sudo pqos -t ${dur} -o /home/n869p538/${enc}_${2}.mem -m 'mbl:1-20;'" &
	cpu_utils=( )
	for i in `seq 1 $(( dur / 5 )) $(( dur - $(( dur / 5)) ))`; do
		sleep $(( $dur / 5 ))
		debug "${FUNCNAME[0]}: ssh ${remote_host} \"top -b -n1 -w512 | grep iperf | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'\""
		cpu_utils+=( "$( ssh ${remote_host} "top -b -n1 -w512 | grep iperf | awk 'BEGIN{sum=0;} {sum+=\$5} END{print sum}'" )" ) #change this when %CPU col changes in top
	done
	scp ${remote_host}:/home/n869p538/${enc}_${2}.mem .

	avg_cpu=$( average_discard_outliers cpu_utils )
	mem_band=$( band_from_mem ${enc}_${2}.mem )
	net_band=$( cat ${enc}_${dur}.iperf | grep -Eo '[0-9]+\.[0-9]+ Gbits/sec' | grep -Eo '[0-9]+\.[0-9]+' )
	echo "$1 $net_band $avg_cpu $mem_band" | tee  ${enc}_${2}.stats
}

# start spec benches on individual cores on the remote host
# 1- test 2-cores to start specs 3-encryption scheme 4-file to request
spec_back_cores_cli_sampling(){
	kill_wrkrs
	kill_procs
	local -n _cores=$2

	debug "${FUNCNAME[0]}: ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1"
	ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1 | tee ${1}_build_log.txt >/dev/null

	debug "build complete.. starting_remote_nginx $3 ${#_cores[@]}"
	start_remote_nginx $3 ${#_cores[@]}
	for c in "${cores[@]}"; do
		debug "${FUNCNAME[0]}: ssh ${remote_host} taskset --cpu-list $c ${remote_spec} --iterations=1 --copies=1 -o csv ${3} &"
		2>&1 ssh ${remote_host} "taskset --cpu-list $c ${remote_spec} --iterations=1 --copies=1 -o csv ${1} " | tee $1_$3_spec_core_$c.cpu &
		sleep 2
	done
	debug "${FUNCNAME[0]}: Waiting for benchmarks to start"
	while [ -z "$( grep 'Running Benchmarks' $1_$3_spec_core_$c.cpu )" ]; do
		sleep 1
		debug "."
	done
	#tail -f -n0 $1_$3_spec_core_$c.cpu | grep -qe "Running Benchmarks"
	debug "bench started starting workers"

	debug "capture_core_mt_async $3 12 64 8h ${remote_ip} $(getport $3) file_256K.txt $1_$3_$(echo "${_cores[*]}" | sed 's/ /_/g')_raw_band"
	capture_core_mt_async $3 12 64 8h ${remote_ip} $(getport $3) ${4} $1_$3_$(echo "${_cores[*]}" | sed 's/ /_/g')_raw_band

	debug "workers started.. starting sampling"
	debug "${FUNCNAME[0]}: ssh ${remote_host} \"echo '' | sudo tee /home/n869p538/${1}_${3}.mem\""
	ssh ${remote_host} "echo '' | sudo tee /home/n869p538/${1}_${3}.mem"


	nginx_cpu_utils=( )
	spec_cpu_utils=( )
	while [ -z "$( grep  "runcpu finished" $1_$3_spec_core_$c.cpu )" ]; do
		sleep 10
		#debug "${FUNCNAME[0]}: ssh ${remote_host} \"top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'\""
		debug "${FUNCNAME[0]}:ssh ${remote_host} \"sudo pqos -t ${dur} -o /home/n869p538/${1}_${3}.mem -m 'mbl:1-${#_cores[@]};'\""
		ssh ${remote_host} "sudo pqos -t 5 -o /home/n869p538/${1}_${3}.mem -m 'mbl:1-${#_cores[@]};'" &
		nginx_cpu_utils+=( "$( ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'" | tee -a ${1}_${3}.nginx_cpu_util )" )
		spec_cpu_utils+=( "$( ssh ${remote_host} "top -b -n1 -w512 | grep -E '(run_base|r_base|mcf_r)' | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'" | tee -a ${1}_${3}.spec_cpu_util )" )

	done
	echo "runcpu_finished"
	kill_wrkrs
	kill_procs
	#tail -f -n0 $1_$3_spec_core_$c.cpu | grep  -qe "runcpu finished"
	debug "scp ${remote_host}:/home/n869p538/${1}_${3}.mem ."
	scp ${remote_host}:/home/n869p538/${1}_${3}.mem .

	nginx_avg_cpu=$( average_all nginx_cpu_utils )
	spec_avg_cpu=$( average_all spec_cpu_utils )
	mem_band=$( band_from_mem_all ${1}_${3}.mem )
	net_band=$( Gbit_from_wrk $1_$3_$(echo "${_cores[*]}" | sed 's/ /_/g')_raw_band ) 

	rems=($(grep 'format: CSV' *.cpu | awk '{print $5}') )
	for i in "${rems[@]}"; do
		scp ${remote_host}:$i . >/dev/null
	done
	spec_stats=$(grep -e 'iteration #1' CPU2017* | awk -F, 'BEGIN{t_avg=0; r_avg=0;} {t_avg+=$3; r_avg+=$4;} END{printf("total_time:%s,rate:%s\n",t_avg,r_avg);}')


	echo "nginx_net_band(Gbit/s):${net_band},spec_rate/spec_time:${spec_stats},mem_band(Gbit/s):$mem_band,nginx_util:$nginx_avg_cpu,spec_util:$spec_avg_cpu," | tee ${1}_${3}.stats

}

# start spec benches on individual cores on the remote host
# 1- test 2-cores to start specs 3-encryption scheme 4-file to request
spec_back_cores_cli_sampling_cache_limit(){
	kill_wrkrs
	kill_procs
	local -n _cores=$2

	debug "${FUNCNAME[0]}: ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1"
	ssh ${remote_host} ${remote_spec} --config=testConfig --action build $1 | tee ${1}_build_log.txt >/dev/null

	debug "build complete.. starting_remote_nginx $3_rdt ${#_cores[@]}"
	start_remote_nginx $3_rdt ${#_cores[@]}
	for c in "${cores[@]}"; do
		debug "${FUNCNAME[0]}: ssh ${remote_host} taskset --cpu-list $c ${remote_spec} --iterations=1 --copies=1 -o csv ${3} &"
		2>&1 ssh ${remote_host} "taskset --cpu-list $c ${remote_spec} --iterations=1 --copies=1 -o csv ${1} " | tee $1_$3_spec_core_$c.cpu &
	done
	debug "${FUNCNAME[0]}: Waiting for benchmarks to start"
	while [ -z "$( grep 'Running Benchmarks' $1_$3_spec_core_$c.cpu )" ]; do
		sleep 1
		debug "."
	done
	#tail -f -n0 $1_$3_spec_core_$c.cpu | grep -qe "Running Benchmarks"
	debug "bench started starting workers"

	debug "capture_core_mt_async $3 12 64 8h ${remote_ip} $(getport $3) file_256K.txt $1_$3_$(echo "${_cores[*]}" | sed 's/ /_/g')_raw_band"
	capture_core_mt_async $3 12 64 8h ${remote_ip} $(getport $3) ${4} $1_$3_$(echo "${_cores[*]}" | sed 's/ /_/g')_raw_band

	debug "workers started.. starting sampling"
	debug "${FUNCNAME[0]}: ssh ${remote_host} \"echo '' | sudo tee /home/n869p538/${1}_${3}.mem\""
	ssh ${remote_host} "echo '' | sudo tee /home/n869p538/${1}_${3}.mem"


	nginx_cpu_utils=( )
	spec_cpu_utils=( )
	while [ -z "$( grep  "runcpu finished" $1_$3_spec_core_$c.cpu )" ]; do
		sleep 10
		#debug "${FUNCNAME[0]}: ssh ${remote_host} \"top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'\""
		debug "${FUNCNAME[0]}:ssh ${remote_host} \"sudo pqos -t ${dur} -o /home/n869p538/${1}_${3}.mem -m 'mbl:1-${#_cores[@]};'\""
		ssh ${remote_host} "sudo pqos -t 5 -o /home/n869p538/${1}_${3}.mem -m 'mbl:1-${#_cores[@]};'" &
		nginx_cpu_utils+=( "$( ssh ${remote_host} "top -b -n1 -w512 | grep nginx | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'" | tee -a ${1}_${3}.nginx_cpu_util )" )
		spec_cpu_utils+=( "$( ssh ${remote_host} "top -b -n1 -w512 | grep -E '(deepsjeng|r_bas|run_base|r_base|mcf_r)' | awk 'BEGIN{sum=0;} {sum+=\$9} END{print sum}'" | tee -a ${1}_${3}.spec_cpu_util )" )

	done
	echo "runcpu_finished"
	kill_wrkrs
	kill_procs
	#tail -f -n0 $1_$3_spec_core_$c.cpu | grep  -qe "runcpu finished"
	debug "scp ${remote_host}:/home/n869p538/${1}_${3}.mem ."
	scp ${remote_host}:/home/n869p538/${1}_${3}.mem .

	nginx_avg_cpu=$( average_all nginx_cpu_utils )
	spec_avg_cpu=$( average_all spec_cpu_utils )
	mem_band=$( band_from_mem_all ${1}_${3}.mem )
	net_band=$( Gbit_from_wrk $1_$3_$(echo "${_cores[*]}" | sed 's/ /_/g')_raw_band ) 

	scp -r ${remote_host}:$(grep 'format: CSV' *.cpu | awk '{print $4}') .
	spec_stats=$( avg_cpu_stats ${1} )


	echo "nginx_net_band(Gbit/s):${net_band},spec_rate/spec_time:${spec_stats},mem_band(Gbit/s):$mem_band,nginx_util:$nginx_avg_cpu,spec_util:$spec_avg_cpu," | tee ${1}_${3}.stats

}

#1-test #2-num cores #3-encryption
single_spec(){
	[ -z "${3}" ] && return -1
	ssh ${remote_host} "echo off | sudo tee /sys/devices/system/cpu/smt/control"
	ssh ${remote_host} 'echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo'
	cores=( `seq 1 $2` )
	spec_back_cores_cli_sampling $1 cores ${3} file_256K.txt
}

#1-test #2-num cores #3-encryption
single_rdt_spec(){
	[ -z "${3}" ] && return -1
	ssh ${remote_host} "echo off | sudo tee /sys/devices/system/cpu/smt/control"
	ssh ${remote_host} 'echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo'
	cores=( `seq 1 $2` )
	spec_back_cores_cli_sampling_cache_limit $1 cores ${3} file_256K.txt
}

multi_enc_spec(){
	encs=(  "https"  "axdimm" )
	for i in "${encs[@]}"; do
		[ ! -d "$i" ] && mkdir $i
		cd $i
		single_spec $1 19 $i
		cd ..
	done
}

multi_enc_spec_single_rdt(){
	encs=( "http" "https" "ktls" "axdimm" )
	for i in "${encs[@]}"; do
		[ ! -d "$i" ] && mkdir $i
		cd $i
		single_rdt_spec $1 19 $i
		cd ..
	done

}
