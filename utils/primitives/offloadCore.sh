#!/bin/bash

#engine libraries
export OPENSSL_ENGINES=/home/n869p538/ktls_client_server/openssl/openssl/lib/engines-1.1
export LD_LIBRARY_PATH=/home/n869p538/ktls_client_server/openssl/openssl/lib:/home/n869p538/crypto_mb/2020u3/lib:/home/n869p538/intel-ipsec-mb/lib
export LDFLAGS='-L/home/n869p538/intel-ipsec-mb/lib -L/home/n869p538/crypto_mb/2020u3/lib'

core=${1}
duration=${2}
fSize=${3}

taskset -c ${core} ./wrk -t1 -c64 -e qatengine -d${duration}s https://192.168.1.2:443/file_${fSize}.txt
