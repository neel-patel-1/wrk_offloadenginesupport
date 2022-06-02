#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

export core=${1}
duration=${2}
fSize=${3}

taskset -c ${core} ${WRK_ROOT}/wrk -t1 -c128  -d${duration} http://${remote_ip}:${http_port}/file_${fSize}.txt
