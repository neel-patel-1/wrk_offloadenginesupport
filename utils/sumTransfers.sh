#!/bin/bash
awk '$2 ~ /GB/ {print $1*8, "GBit/s"; sum+=$1*8;} $2 ~ /MB/ {printf "%.2f %s\n", ($1*8)/1000, "GBit/s";sum+=($1*8)/1000;} END{printf "%.2f %s\n", sum, "GBit/s total"}' wrk_files/offload_${1}_${2}.per_core_throughput
