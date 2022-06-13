#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

[ ! -d "$cli_ossls" ] && mkdir $cli_ossls
cd $cli_ossls

#openssl
cd ${cli_ossls}

[ ! -f "${cli_ossls}/openssl-3.0.0.tar.gz" ] && cd ${cli_ossls} && wget https://www.openssl.org/source/openssl-3.0.0.tar.gz
[ ! -d "${cli_ossls}/openssl-3.0.0" ] && cd ${cli_ossls} && tar xvf openssl-3.0.0.tar.gz
if [ ! -f "${cli_ossls}/openssl-3.0.0/libssl.so.3" ]; then
	cd ${cli_ossls}/openssl-3.0.0
	./Configure shared enable-ktls enable-ssl3 enable-threads shared linux-x86_64
	make -j
fi
