#!/bin/bash
out_file=${1}
#verbose
#awk '$2 ~ /GB/ {print $1*8, "GBit/s"; sum+=$1*8;} $2 ~ /MB/ {printf "%.2f %s\n", ($1*8)/1000, "GBit/s";sum+=($1*8)/1000;} END{printf "%.2f %s\n", sum, "GBit/s total"}' ${out_file}
awk '$2 ~ /GB/ {sum+=$1*8;} $2 ~ /MB/ {sum+=($1*8)/1000;} END{printf "%.2f %s\n", sum, "GBit/s total"}' ${out_file}
