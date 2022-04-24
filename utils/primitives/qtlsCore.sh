#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
export OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1
export LD_LIBRARY_PATH=$OPENSSL_LIB

core=${1}
duration=${2}
fSize=${3}

taskset -c ${core} ${WRK_ROOT}/wrk -t1 -c64  -d${duration} https://${remote_ip}:443/file_${fSize}.txt
