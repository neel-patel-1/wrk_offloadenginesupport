#!/bin/bash

#100GBit/s / 10 Gbit per IP ~ 10 IPs
num_ips=10
client=n869p538@castor.ittc.ku.edu

for i in `seq 2 $((num_ips + 2))`; do
    sudo ifconfig ens4f0:$i 192.168.${i}.1
done
