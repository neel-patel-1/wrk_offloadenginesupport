#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src
source $WRK_ROOT/vars/environment.src

source ${test_dir}/debug_utils.sh

# SINGLE CORE METHOD FUNCTIONS #
# PARAMS: 1-core (to pin clients) 2-clients (ie. 64 clients on a single core) 3-duration 4-remote_ip 5-port 6-file_path (starts at root)
# OPTIONAL PARAMS: 7-additional wrk options
http_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "80" ] && echo "Non default http port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	taskset -c ${1} ${default_wrk} -t1 -c${2}  -d${3} ${7} http://${4}:${5}/${6}
}

http_mt_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "80" ] && echo "Non default http port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	${default_wrk} -t${1} -c${2}  -d${3} ${7} http://${4}:${5}/${6}
}

https_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	taskset -c ${1} ${default_wrk} -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}
}

axdimm_test_mt_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export OPENSSL_ENGINES=$AXDIMM_TEST_ENGINES
	export LD_LIBRARY_PATH=$AXDIMM_TEST_OSSL_LIBS:$AXDIMM_TEST_ENGINES:$LD_LIBRARY_PATH

	${engine_wrk} -e qatengine -t${1} -c${2} -d${3} ${7} https://${4}:${5}/${6}
}

https_mt_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	# split https requests between two file versions
	${default_wrk} -t${1} -c${2} -d${3} ${7} https://${4}:${5}/${6}
}

https_rdt_mt_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	# split https requests between two file versions
	${WRK2} --latency -R 150000 -t${1} -s ${WRK_ROOT}/many_req.lua -c${2} -d${3} ${7} https://${4}:${5}
}

http_rdt_mt_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "80" ] && echo "Non default http port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	# split https requests between two file versions
	${WRK2} --latency -R 150000 -t${1} -s ${WRK_ROOT}/many_req.lua -c${2} -d${3} ${7} http://${4}:${5}
}

http_gzip_mt_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "80" ] && echo "Non default http port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	# split https requests between two file versions
	${WRK2} --latency -R 150000 -t${1} -H"accept-encoding: gzip, deflate" -s ${WRK_ROOT}/many_req.lua -c${2} -d${3} ${7} http://${4}:${5}
}

https_gzip_mt_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "80" ] && echo "Non default http port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	# split https requests between two file versions
	${WRK2} --latency -R 150000 -t${1} -H"accept-encoding: gzip, deflate" -s ${WRK_ROOT}/many_req.lua -c${2} -d${3} ${7} https://${4}:${5}
}

#offload cores
axdimm_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export OPENSSL_ENGINES=$AXDIMM_ENGINES
	export LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_ENGINES

	taskset -c ${1} ${engine_wrk} -e qatengine -t1 -c${2} -d${3} ${7} https://${4}:${5}/${6}
}


axdimm_mt_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export OPENSSL_ENGINES=$AXDIMM_ENGINES
	export LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_ENGINES:$AXDIMM_DIR/lib

	${engine_wrk} -e qatengine -t${1} -c${2} -d${3} ${7} https://${4}:${5}/${6}
}

axdimm_rdt_mt_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export OPENSSL_ENGINES=$AXDIMM_ENGINES
	export LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_ENGINES:$AXDIMM_DIR/lib

	${engine_wrk} --latency -e qatengine -s many_req.lua -t${1} -c${2} -d${3} ${7} https://${4}:${5}
}

qtls_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export LD_LIBRARY_PATH=$cli_ossls/openssl-1.1.1f
	taskset -c ${1} ${default_wrk} -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}
}

qtlsold_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	sudo env \
	OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1 \
	LD_LIBRARY_PATH=$OPENSSL_LIBS \
	taskset -c ${1} ${engine_wrk} -t1 -c${2} -d${3} ${7} https://${4}:${5}/${6}
}

qtls_mt_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	sudo env \
	OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1 \
	LD_LIBRARY_PATH=$OPENSSL_LIBS \
	${engine_wrk} -t${1} -c${2} -d${3} ${7} https://${4}:${5}/${6}
}

qtlsdbg_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	sudo env \
	OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1 \
	LD_LIBRARY_PATH=$OPENSSL_LIBS \
	gdb --args ${WRK_ROOT}/wrk -t1 -c${2} -e qatengine -d${3} ${7} https://${4}:${5}/${6}
}

ktlsold_core(){ #does not use receive side ktls
	export LD_LIBRARY_PATH=$KTLS_OSSL_LIBS
	debug "${FUNCNAME[0]}: taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}"
	debug "${FUNCNAME[0]}: libs -> $(ldd ${WRK_ROOT}/wrk)"
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}
}

ktls_core(){
	export LD_LIBRARY_PATH=$ktls_drop_ossl
	#debug "$(ldd ${ktls_drop_wrk})"
	debug "${FUNCNAME[0]}: taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}"
	taskset -c ${1} $ktls_drop_wrk -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}
}

ktls_mt_core(){
	export LD_LIBRARY_PATH=$ktls_drop_ossl
	#debug "$(ldd ${ktls_drop_wrk})"
	debug "${FUNCNAME[0]}: $ktls_drop_wrk -t${1} -c${2}  -d${3} ${7} https://${4}:${5}/${6}"
	$ktls_drop_wrk -t${1} -c${2}  -d${3} ${7} https://${4}:${5}/${6}
	#${default_wrk} -t${1} -c${2} -d${3} ${7} https://${4}:${5}/${6}
}

link_core(){
	export LD_LIBRARY_PATH=$ktls_drop_ossl
	debug "$(ldd ${ktls_drop_wrk})"
	$ktls_drop_ossl/apps/openssl version
}
# PARAMS: 1-method 2-core (to pin clients) 3-clients (ie. 64 clients on a single core) 4-duration 5-remote_ip 6-port 7-file_path (starts at root) 8-output file 9-optional argumetns to wrk
capture_core_async(){
	[ -z "${7}" ] && echo "${FUNCNAME[0]}: missing params"
	debug "${FUNCNAME[0]}: method:$1 core:$2 clients:$3 duration:$4 ip:$5 port:$6 object:$7 wrk_stats:$8 additional:$9"
	${1}_core $2 $3 $4 $5 $6 $7 $9 > $8 &
	debug "${FUNCNAME[0]}: asyncronous core $2 started ..."
}

# PARAMS: 1-method 2-number of threads 3-clients (ie. 64 clients on a single core) 4-duration 5-remote_ip 6-port 7-file_path (starts at root) 8-output file 9-optional argumetns to wrk
capture_core_mt_async(){
	[ -z "${7}" ] && echo "${FUNCNAME[0]}: missing params"
	#start remote server
	debug "${FUNCNAME[0]}: method:$1 core:$2 clients:$3 duration:$4 ip:$5 port:$6 object:$7 wrk_stats:$8 additional:$9"
	${1}_mt_core $2  $3 $4 $5 $6 ${7} $9 > $8 &
	debug "${FUNCNAME[0]}: $2 threads with $3 clients started ..."
}

# PARAMS: 1-method 2-number of threads 3-clients (ie. 64 clients on a single core) 4-duration 5-remote_ip 6-port 7-file_path (starts at root) 8-output file 9-optional argumetns to wrk
capture_core_mt_async_mf(){
	[ -z "${7}" ] && echo "${FUNCNAME[0]}: missing params"
	#start remote server
	debug "${FUNCNAME[0]}: method:$1 core:$2 clients:$3 duration:$4 ip:$5 port:$6 object:$7 wrk_stats:$8 additional:$9"
	# number of cores is 12
	wrkrs=${2}
	cli_per_wrk=$(( $3 / $wrkrs ))
	td_per_wrk=$(( $2 / $wrkrs ))
	debug "${FUNCNAME[0]}: Num wrkrs: $wrkrs cli_per_wrk: $cli_per_wrk td_per_wrk: $td_per_wrk"
	# number of clients >= # threads
	[ "$cli_per_wrk" -lt "$td_per_wrk" ] && echo "${FUNCNAME[0]} improper number of clients for worker wrks" && exit -1
	# make sure files are on the DUT
	for i in $(seq 1 $wrkrs); do
		gen_file_dut_name $(echo $7 | sed -E -e 's/B//g' -e 's/file_([0-9]+.).txt/\1/g') ${7}f${i}
	done

	for i in $(seq 1 $wrkrs); do
		${1}_mt_core  $td_per_wrk $cli_per_wrk $4 $5 $6 ${7}f${i} $9 >> $8 &
		debug "${FUNCNAME[0]} :${1}_mt_core $cli_per_wrk $td_per_wrk $4 $5 $6 ${7}f${i} $9 >> $8 &"
	done
}

# PARAMS: 1-method 2-core (to pin clients) 3-clients (ie. 64 clients on a single core) 4-duration 5-remote_ip 6-port 7-file_path (starts at root) 8-output file 9-optional argumetns to wrk
capture_core_block(){
	[ -z "${7}" ] && echo "${FUNCNAME[0]}: missing params"
	${1}_core $2 $3 $4 $5 $6 $7 $9 > $8
}

# PARAMS: 1-method 2-clients_per_core  3-duration 4-remote_ip 5-port 6-file to fetch 7-output directory 8:end-list of cores to use 9-optional wrk params
capture_cores_async(){
	[ -z "$8" ] && echo "${FUNCNAME[0]}: missing params" && return -1
	[ ! -d "$7" ] && echo "${FUNCNAME[0]}: missing output directory" && return -1
	local -n _core_list_async=$8
	for i in "${_core_list_async[@]}"; do	
		echo -n "" > $7/core_$i
		debug "${FUNCNAME[0]}: method:$1 core:$i clients:$2 duration:$3 ip:$4 port:$5 object:$6 wrk_stats:$7/core_$i additional:$9"
		capture_core_async $1 $i $2 $3 $4 $5 $6 $7/core_$i $9
	done
	debug "${FUNCNAME[0]}: all asyncronous cores started (${_core_list_async[*]}) ..."

}

#1- method 
getport(){
	[ -z "$1" ] && echo "${FUNCNAME[0]}: missing params" && return -1
	if [[ "${1}" == http_* ]]; then
		echo "80"
	else
		echo "443"
	fi
}
#capture_cores_async $1 $2 $3 $4 $5 $6
