#!/bin/bash
export WRK_ROOT=$(pwd)
export spec_output=$WRK_ROOT/spec_res

copies=${1}

file=csv_results/${copies}copies_spec_rate.csv
echo ",runtime,rate,bandwidth" > $file
for i in $spec_output/*${copies}copies.spec
do
	row=$(echo "$i" | sed -e 's/.*\/\([a-z][a-z]*\)_.*/\1,/')
	row+=$(head -n 1 $i | sed 's/ /,/' )
	row+=","
	row+=$(tail -n 1 $i | sed 's/[a-zA-Z][a-zA-Z/ ]*//' )
	echo $row  >> $file
done
