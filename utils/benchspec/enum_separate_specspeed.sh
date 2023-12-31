#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
export spec_output=$WRK_ROOT/spec_res
[ ! -d "$spec_output" ] && mkdir $spec_output

#declare -a server_cores=("10" "15" "20" )
declare -a server_cores=("10" )
#declare -a fsizes=("4K" "16K" "64K" "128K" "256K" )
declare -a fsizes=( "256K" )
#declare -a methods=( "offload" "http" "https" "httpsendfile" "qtls" )
declare -a methods=( "offload" "http" "https" "httpsendfile" )

declare -a copies=( "1" "5" )

#16 client copies
for l in "${copies[@]}"
do
	for k in "${methods[@]}"
	do
		for j in "${fsizes[@]}"
		do
			for i in "${server_cores[@]}"
			do
				outfile=$spec_output/505_mcf_${k}_rate_${i}core_${j}_${l}copies_separate.spec
				echo -n "" > $outfile
				./utils/benchspec/separatebackground_speed.sh $k 16 $i $j $l | grep -e '[0-9][0-9]*' > $outfile
			done
		done
	done
done

