#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
server=$remote_user
if=$remote_net_dev
getips="ip addr show $if | grep 192 | grep : | awk '{print $2}' | grep -Eo '\b([0-9]{1,3}\.){3}[0-9]{1,2}\b'"

ips=$(ssh $server $getips)
ctr=1
for ip in $ips; do
	sub=$(echo "$ip " | sed 's/[0-9][0-9]*\.[0-9][0-9]*\.\([0-9][0-9]*\)\.[0-9][0-9]*/\1/g' | tr -d ' ' )
	ctr=$(( $ctr + 1))
	sudo ifconfig $local_net_dev:$ctr 192.168.${sub}.1/24
done
