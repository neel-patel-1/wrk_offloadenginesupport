#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
#engine libraries
export OPENSSL_ENGINES=$AXDIMM_OFFLOAD_OPENSSL_ENGINE
export LD_LIBRARY_PATH=$AXDIMM_OFFLOAD_OPENSSL_ENGINE:/home/n869p538/crypto_mb/2020u3/lib:/home/n869p538/intel-ipsec-mb/lib
export LDFLAGS='-L/home/n869p538/intel-ipsec-mb/lib -L/home/n869p538/crypto_mb/2020u3/lib'

core=${1}
duration=${2}
fSize=${3}

taskset -c ${core} ${WRK_ROOT}/wrk -t1 -c64 -e qatengine -d${duration} https://192.168.1.2:443/file_${fSize}.txt
#$OPENSSL_ENGINES/../../bin/openssl engine -t -c -v qatengine
