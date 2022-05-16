#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
export OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1
export LD_LIBRARY_PATH=$OPENSSL_LIBS

core=${1}
duration=${2}
fSize=${3}
err_file=fail_$core.out

sudo env \
OPENSSL_ENGINES=$OPENSSL_LIBS/engines-1.1 \
LD_LIBRARY_PATH=$OPENSSL_LIBS \
taskset -c ${core} ${WRK_ROOT}/wrk -e qatengine -t1 -c64  -d${duration} https://${remote_ip}:443/file_${fSize}.txt 2>&1 | tee ${err_file} 

if [ ! -z "$( grep -E 'failed to start' $err_file )" ]; then
	>&2 echo "qtls client engine failed to initialize..."
	>&2 echo "attempting to reinstall drivers"
	#remove qat
	sudo rmmod qat_c62x
	sudo rmmod usdm_drv
	sudo rmmod intel_qat
	sudo insmod ${ICP_ROOT}/build/qat_c62x.ko
	sudo insmod ${ICP_ROOT}/build/usdm_drv.ko
	sudo insmod ${ICP_ROOT}/build/intel_qat.ko

	sudo service qat_service start
	rm -f ${err_file}
	exit
fi
#rm -f $err_file
#$OPENSSL_ENGINES/../../bin/openssl engine -t -c -v qatengine
#taskset -c ${core} ${WRK_ROOT}/wrk -e qatengine -t1 -c64  -d${duration} https://192.168.${sub}.2:443/file_${fSize}.txt
#$OPENSSL_ENGINES/../../bin/openssl version
