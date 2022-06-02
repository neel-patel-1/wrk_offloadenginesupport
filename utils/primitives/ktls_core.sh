#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


export core=${1}
duration=${2}
fSize=${3}

[ "$(ethtool -k ${local_net_dev} | grep tls-hw-rx-offload | awk '{print $2}')

taskset -c ${core} ${WRK_ROOT}/wrk -t1 -c64  -d${duration} https://${remote_ip}:443/file_${fSize}.txt
