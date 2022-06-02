#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
#engine libraries
export OPENSSL_ENGINES=$AXDIMM_ENGINES
export LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_ENGINES

export core=${1}
duration=${2}
fSize=${3}

#export LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_ENGINES:$AXDIMM_DIR/crypto_mb/2020u3/lib:$AXDIMM_DIR/ipsec-mb/0.55/lib
taskset -c ${core} ${WRK_ROOT}/wrk -t1 -c64 -e qatengine -d${duration} https://${remote_ip}:${https_port}/file_${fSize}.txt
