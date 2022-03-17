#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
export spec_output=$WRK_ROOT/spec_res

copies=${1}

file=$WRK_ROOT/csv_results/${copies}copies_525_x264_diffcores.csv
echo ",runtime,rate,bandwidth" > $file
for i in $spec_output/525_x264_*_${copies}copies_different.spec
do
	row=$(echo "$i" | sed -e 's/.*\/\([a-z0-9][a-z0-9]*\)_\([a-z0-9][a-z0-9]*\)_\([a-z0-9][a-z0-9]*\).*/\3,/')
	row+=$(head -n 1 $i | sed 's/ /,/' )
	row+=","
	row+=$(tail -n 1 $i | sed 's/[a-zA-Z][a-zA-Z/ ]*//' )
	echo $row  >> $file
done
