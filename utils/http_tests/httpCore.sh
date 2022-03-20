#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

core=${1}
duration=${2}
fSize=${3}
sub=${4}

taskset -c ${core} ${WRK_ROOT}/wrk -t1 -c64  -d${duration} http://192.168.${sub}.2:80/file_${fSize}.txt
