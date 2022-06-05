#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


# SINGLE CORE METHOD FUNCTIONS #
# PARAMS: 1-core (to pin clients) 2-clients (ie. 64 clients on a single core) 3-duration 4-remote_ip 5-port 6-file_path (starts at root)
# OPTIONAL PARAMS: 7-additional wrk options
http_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "80" ] && echo "Non default http port: $5"
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} http://${4}:${5}/${6}
}

https_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2}  -d${3} ${7} http://${4}:${5}/${6}
}

#offload cores
axdimm_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	export OPENSSL_ENGINES=$AXDIMM_ENGINES
	export LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_ENGINES

	taskset -c ${1} ${WRK_ROOT}/wrk -e qatengine -t1 -c${2} -d${3} ${7} http://${4}:${5}/${6}
}

qtls_core(){
	[ -z "$6" ] && echo "${FUNCNAME[0]}: missing params"
	[ "$5" != "443" ] && echo "Non default https port: $5"
	sudo env \
	OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1 \
	LD_LIBRARY_PATH=$OPENSSL_LIBS \
	echo "taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2} -e qatengine -d${3} ${7} https://${4}:${5}/${6}"
	taskset -c ${1} ${WRK_ROOT}/wrk -t1 -c${2} -e qatengine -d${3} ${7} https://${4}:${5}/${6}
}
