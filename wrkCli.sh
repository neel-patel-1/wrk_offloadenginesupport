#!/bin/bash
export OPENSSL_ENGINES=/home/n869p538/ktls_client_server/openssl/openssl/lib/engines-1.1
export LD_LIBRARY_PATH=/home/n869p538/ktls_client_server/openssl/openssl/lib:/home/n869p538/crypto_mb/2020u3/lib:/home/n869p538/intel-ipsec-mb/lib
export LDFLAGS='-L/home/n869p538/intel-ipsec-mb/lib -L/home/n869p538/crypto_mb/2020u3/lib'
if [ "${1}" = "tlso" ]; then 
	./wrk -t16 -c1024 -e qatengine -d${2}s https://192.168.1.2:443/file5.txt
elif [ "${1}" = "tls" ]; then 
	./wrk -t16 -c1024 -d${2}s https://192.168.1.2:443/file5.txt
else
	./wrk -t16 -c1024 -d${2}s http://192.168.1.2:80/file5.txt
fi
