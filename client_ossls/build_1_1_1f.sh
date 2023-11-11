#!/bin/bash
export CDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export WRK_ROOT=$CDIR/../
source $WRK_ROOT/vars/env.src

[ ! -d "$cli_ossls" ] && mkdir $cli_ossls
echo "$cli_ossls"

#openssl
cd ${cli_ossls}

[ ! -f "${cli_ossls}/openssl-1.1.1f.tar.gz" ] && cd ${cli_ossls} && wget --no-check-certificate https://www.openssl.org/source/old/1.1.1/openssl-1.1.1f.tar.gz
[ ! -d "${cli_ossls}/openssl-1.1.1f" ] && cd ${cli_ossls} && tar xvf openssl-1.1.1f.tar.gz
if [ ! -f "${cli_ossls}/openssl-1.1.1f/libssl.so" ]; then
	cd ${cli_ossls}/openssl-1.1.1f
	./Configure shared enable-threads shared linux-x86_64
	make -j
fi
