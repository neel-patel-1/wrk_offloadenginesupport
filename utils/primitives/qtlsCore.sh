#!/bin/bash


core=${1}
duration=${2}
fSize=${3}

taskset -c ${core} ${WRK_ROOT}/wrk -t1 -c64  -d${duration} https://192.168.1.2:443/file_${fSize}.txt
