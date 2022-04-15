#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
export OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1
export LD_LIBRARY_PATH=$OPENSSL_LIBS

core=${1}
duration=${2}
fSize=${3}
sub=${4}

sudo env \
OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1 \
LD_LIBRARY_PATH=$OPENSSL_LIBS \
${WRK_ROOT}/wrk -e qatengine -t1 -c64  -d${duration} https://192.168.${sub}.2:443/file_${fSize}.txt
#$OPENSSL_ENGINES/../../bin/openssl engine -t -c -v qatengine
#taskset -c ${core} ${WRK_ROOT}/wrk -e qatengine -t1 -c64  -d${duration} https://192.168.${sub}.2:443/file_${fSize}.txt
#$OPENSSL_ENGINES/../../bin/openssl version
