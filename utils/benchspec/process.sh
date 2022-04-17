#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

cd $outdir

echo "Bandwidth(GBit/s)" > $outfile
echo "Benchmarks,$(echo ${tests[*]} | sed -e 's/ /,/g' )" >> $outfile
for f in "${methods[@]}"; do 
	bands=() 
	bands+=("$f") 
	for g in "${tests[@]}"; do  
		bands+=( "$(cat ${g}*_${f}_*_band | grep -Eo '[0-9.][0-9.]*') " )
       	done
	echo "$(echo ${bands[*]} | sed -e 's/ /,/g' )" >> $outfile
done

echo "" >> $outfile

echo "Score(Higher is better)" >> $outfile
echo "Benchmarks,$(echo ${tests[*]} | sed -e 's/ /,/g' )" >> $outfile
for g in "${methods[@]}"; do 
	sc=()
	sc+=("$g")
	for f in "${tests[@]}"; do 
		sc+=( "$(grep -E "$f(_r)?\s\s*[0-9].*" ${f}*_${g}_* | head -n 1 | awk '{print $4}')" )
       	done 
	echo "$(echo ${sc[*]} | sed -e 's/ /,/g' )" >> $outfile
done

