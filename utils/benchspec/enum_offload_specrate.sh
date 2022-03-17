#!/bin/bash
export WRK_ROOT=$(pwd)
export spec_output=$WRK_ROOT/spec_res
[ ! -d "$spec_output" ] && mkdir $spec_output

#declare -a server_cores=("10" "15" "20" )
declare -a server_cores=("10" )
#declare -a fsizes=("4K" "16K" "64K" "128K" "256K" )
declare -a fsizes=( "256K" )
#declare -a methods=( "offload" "http" "https" "httpsendfile" )
declare -a methods=( "qtls" )

declare -a copies=( "1" "5" )

#16 client threads
for l in "${copies[@]}"
do
	for k in "${methods[@]}"
	do
		for j in "${fsizes[@]}"
		do
			for i in "${server_cores[@]}"
			do
				outfile=$spec_output/525_x264_${k}_rate_${i}core_${j}_${l}copies_different.spec
				echo -n "" > $outfile
				./utils/benchspec/backgroundtls.sh $k 16 $i $j $l | grep -e '[0-9][0-9]*' > $outfile
			done
		done
	done
done
