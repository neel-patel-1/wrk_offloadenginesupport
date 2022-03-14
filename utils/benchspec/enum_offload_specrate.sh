#!/bin/bash
export WRK_ROOT=$(pwd)
export spec_output=$WRK_ROOT/spec_res
[ ! -d "$spec_output" ] && mkdir $spec_output

#declare -a server_cores=("10" "15" "20" )
declare -a server_cores=("10" )
#declare -a fsizes=("4K" "16K" "64K" "128K" "256K" )
declare -a fsizes=( "256K" )
#declare -a methods=( "offload" "http" "https" "httpsendfile" )
declare -a methods=( "offload" )

#16 client threads
for k in "${methods[@]}"
do
	for j in "${fsizes[@]}"
	do
		outfile=$spec_output/${k}_rate_${i}core_${j}.spec
		echo -n "" > $outfile
		for i in "${server_cores[@]}"
		do
			./utils/benchspec/backgroundtls.sh offload 16 $i $j | grep -e '[0-9][0-9]*' > $outfile
		done
	done
done
