#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

[ ! -z "$fSize" ] && echo "Cannot vaary filesize" && exit

export prepend="${band_test_name}"
export outdir=${WRK_ROOT}/csv_res/$prepend

[ ! -d "${WRK_ROOT}/csv_res/$prepend" ] && mkdir -p ${WRK_ROOT}/csv_res/$prepend

outfile=$outdir/bandwidth_comp_$(date +%T).csv
[ ! -f "$outfile" ] && touch $outfile

echo -n "" > $outfile

echo "File Size,$(echo ${file_sizes[*]} | sed -e 's/ /,/g'  )" >> $outfile
for i in "${methods[@]}"; do
	row=$i
	band=( "$i" )
	for f in "${file_sizes[@]}" 
	do
		export fSize=$f
		band+=("$(${band_dir}/maximum_${i}_throughput.sh)")
	done

	echo "${row},$(echo ${band[*]} | sed -e 's/[a-zA-Z/]//g' -e 's/\s\s*/,/g' -e 's/,$//g' )" >> $outfile

done
cp $outfile $csv_export
exit
