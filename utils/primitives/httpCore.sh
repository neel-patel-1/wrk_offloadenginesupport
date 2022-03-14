#!/bin/bash


core=${1}
duration=${2}
fSize=${3}

taskset -c ${core} ./wrk -t1 -c64  -d${duration} http://192.168.1.2:80/file_${fSize}.txt
