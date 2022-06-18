#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
source $WRK_ROOT/vars/env.src #ktls wrk loc

export LD_LIBRARY_PATH=$KTLS_OSSL_LIBS

export core=${1}
duration=${2}
fSize=${3}


taskset -c ${core} $ktls_drop_wrk -t1 -c${core_conn}  -d${duration} https://${remote_ip}:443/file_${fSize}.txt
