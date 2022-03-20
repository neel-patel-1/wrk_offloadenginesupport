#!/bin/bash

export ROOT_DIR=/home/n869p538/wrk_offloadenginesupport
source $ROOT_DIR/vars/environment.src

ips=$($QTLS_TEST_DIR/getIps.sh)
for i in $ips; do
	echo $i
done
