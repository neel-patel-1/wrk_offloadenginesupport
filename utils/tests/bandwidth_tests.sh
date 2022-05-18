#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


export prepend="${band_test_name}"

[ ! -d "${WRK_ROOT}/csv_res/$prepend" ] && mkdir -p ${WRK_ROOT}/csv_res/$prepend

outfile=${WRK_ROOT}/csv_res/$prepend/bandwidth_comp_$(date +%T).csv
[ ! -f "$outfile" ] && touch $outfile

echo -n "" > $outfile

echo "File Size,$(echo ${file_sizes[*]} | sed -e 's/ /,/g'  )" >> $outfile
for i in "${methods[@]}"; do
	row=$(echo $i | grep -Eo 'maximum_[a-z]*' | sed 's/maximum_//g')
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
