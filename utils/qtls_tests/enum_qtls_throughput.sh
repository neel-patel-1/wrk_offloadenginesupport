#!/bin/bash
output_dir=/home/n869p538/wrk_offloadenginesupport/results

declare -a arr=("4K" "16K" "64K" "128K" "256K" )

max_cores=${1}

for i in "${arr[@]}"
do
	output=$output_dir/qtls_throughput_vs_num_cores_$i.csv
	echo -n "" > $output
	for j in `seq 1 ${max_cores}`; do
		# run test for 20s with 16 client threads each making 64 connections
		GBPS=$(./utils/bandwidth_measurement/maximum_qtls_throughput.sh 20 16 $i $j | awk '{print $1}')
		echo "$j, $GBPS" >> $output

	done
done
