#!/bin/bash
server=192.168.1.2
if=ens4f0
getips="ip addr show $if | grep 192 | grep : | awk '{print $2}' | grep -Eo '\b([0-9]{1,3}\.){3}[0-9]{1,2}\b'"

ips=$(ssh $server $getips)
for ip in $ips; do
	echo -n "$ip "
done
