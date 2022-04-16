#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src


export duration=10
export numcores=10
export numServerCores=10
export prepend="max_band_$(date +%T)"

[ ! -d "${WRK_ROOT}/csv_res/$prepend" ] && mkdir -p ${WRK_ROOT}/csv_res/$prepend

outfile=${WRK_ROOT}/csv_res/$prepend/bandwidth_comp.csv
[ ! -f "$outfile" ] && touch $outfile

echo -n "" > $outfile

declare -a arr=("4K" "16K" "64K" "128K" "256K" )
echo "File Size(KB),$(echo ${arr[*]} | sed -e 's/ /,/g' -e 's/K//g' )" >> $outfile
for i in ${band}/maximum*; do
	row=$(echo $i | grep -Eo 'maximum_[a-z]*' | sed 's/maximum_//g')
	band=()
	for f in "${arr[@]}" 
	do
		export fSize=$f
		band+=("$($i)")
	done

	echo "${row},$(echo ${band[*]} | sed -e 's/[a-zA-Z/]//g' -e 's/ /,/g' )" >> $outfile

done
cp $outfile $csv_export
exit
