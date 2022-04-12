#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
export OPENSSL_ENGINES=${WRK_ROOT}/async_nginx_build/Builds/openssl/lib/engines-1.1
export LD_LIBRARY_PATH=${WRK_ROOT}/async_nginx_build/Builds/openssl/lib:/home/n869p538/crypto_mb/2020u3/lib:/home/n869p538/intel-ipsec-mb/lib
export LDFLAGS="-L/home/n869p538/intel-ipsec-mb/lib -L/home/n869p538/crypto_mb/2020u3/lib"

core=${1}
duration=${2}
fSize=${3}
sub=${4}

sudo env \
OPENSSL_ENGINES=${WRK_ROOT}/async_nginx_build/Builds/openssl/lib/engines-1.1 \
LD_LIBRARY_PATH=${WRK_ROOT}/async_nginx_build/Builds/openssl/lib:/home/n869p538/crypto_mb/2020u3/lib:/home/n869p538/intel-ipsec-mb/lib \
LDFLAGS="-L/home/n869p538/intel-ipsec-mb/lib -L/home/n869p538/crypto_mb/2020u3/lib" \
taskset -c ${core} ${WRK_ROOT}/wrk -e qatengine -t1 -c64  -d${duration} https://192.168.${sub}.2:443/file_${fSize}.txt
#$OPENSSL_ENGINES/../../bin/openssl engine -t -c -v qatengine
#$OPENSSL_ENGINES/../../bin/openssl version
