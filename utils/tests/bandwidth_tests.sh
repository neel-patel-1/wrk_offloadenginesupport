#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


export prepend="max_band_10m_axdimm_256K$(date +%T)"

[ ! -d "${WRK_ROOT}/csv_res/$prepend" ] && mkdir -p ${WRK_ROOT}/csv_res/$prepend

outfile=${WRK_ROOT}/csv_res/$prepend/bandwidth_comp.csv
[ ! -f "$outfile" ] && touch $outfile

echo -n "" > $outfile

echo "File Size,$(echo ${arr[*]} | sed -e 's/ /,/g'  )" >> $outfile
for i in "${methods[@]}"; do
	row=$(echo $i | grep -Eo 'maximum_[a-z]*' | sed 's/maximum_//g')
	band=()
	for f in "${file_sizes[@]}" 
	do
		export fSize=$f
		band+=("$(${band}/maximum_${i}_throughput.sh)")
	done

	echo "${row},$(echo ${band[*]} | sed -e 's/[a-zA-Z/]//g' -e 's/\s\s*/,/g' -e 's/,$//g' )" >> $outfile

done
cp $outfile $csv_export
exit
