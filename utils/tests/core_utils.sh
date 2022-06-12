#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

source ${test_dir}/debug_utils.sh
# SINGLE CORE METHOD FUNCTIONS #
# PARAMS: 1-core (to pin clients) 2-clients (ie. 64 clients on a single core) 3-duration 4-remote_ip 5-port 6-file_path (starts at root)
# OPTIONAL PARAMS: 7-additional wrk options
http_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "80" ] && echo "Non default http port: $5"
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} http://${4}:${5}/${6}
}

https_core(){
	[ -z "$5" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}
}

#offload cores
axdimm_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export OPENSSL_ENGINES=$AXDIMM_ENGINES
	export LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_ENGINES

	taskset -c ${1} ${WRK_ROOT}/wrk -e qatengine -t1 -c${2} -d${3} ${7} https://${4}:${5}/${6}
}

qtls_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	sudo env \
	OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1 \
	LD_LIBRARY_PATH=$OPENSSL_LIBS \
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2} -e qatengine -d${3} ${7} https://${4}:${5}/${6}
}

ktls_core(){
	export LD_LIBRARY_PATH=$KTLS_OSSL_LIBS
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} https://${4}:${5}/${6}
}

# PARAMS: 1-method 2-core (to pin clients) 3-clients (ie. 64 clients on a single core) 4-duration 5-remote_ip 6-port 7-file_path (starts at root)8-optional argumetns to wrk
capture_core_async(){
	[ -z "${7}" ] && echo "${FUNCNAME[0]}: missing params"
	${1}_core $2 $3 $4 $5 $6 $8 > $7 &
	debug "${FUNCNAME[0]}: asyncronous core $2 started ..."
}

# PARAMS: 1-method 2-core (to pin clients) 3-clients (ie. 64 clients on a single core) 4-duration 5-remote_ip 6-port 7-file_path (starts at root) 8-optional argumetns to wrk
capture_core_block(){
	[ -z "${7}" ] && echo "${FUNCNAME[0]}: missing params"
	${1}_core $2 $3 $4 $5 $6 $8 > $7
}

# PARAMS: 1-method 2-clients_per_core  3-duration 4-remote_ip 5-port 6-output directory (starts at root) 7:end-list of cores to use
capture_cores_async(){
	[ -z "$7" ] && echo "${FUNCNAME[0]}: missing params" && return -1
	[ ! -d "$6" ] && echo "${FUNCNAME[0]}: missing output directory" && return -1
	local -n _core_list_async=$7
	for i in "${_core_list_async[@]}"; do	
		echo -n "" > $6/core_$i
		capture_core_async $1 $i $2 $3 $4 $5 $6/core_$i
	done
	debug "${FUNCNAME[0]}: all asyncronous cores started (${_core_list_async[*]}) ..."

}


#capture_cores_async $1 $2 $3 $4 $5 $6
