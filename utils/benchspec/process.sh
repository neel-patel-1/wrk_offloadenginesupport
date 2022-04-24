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
		bands+=( "$(cat ${g}_${f}_*_band | grep -Eo '[0-9.][0-9.]*') " )
       	done
	echo "$(echo ${bands[*]} | sed -e 's/ /,/g' )" >> $outfile
done

echo "" >> $outfile

echo "Rate/Time" >> $outfile
echo "Benchmarks,$(echo ${tests[*]} | sed -e 's/ /,/g' )" >> $outfile
for g in "${methods[@]}"; do 
	sc=()
	sc+=("$g")
	for f in "${tests[@]}"; do 
		sc+=( "$(grep -E "$f(_r)?\s\s*[0-9].*" ${f}_${g}_* | head -n 1 | awk '{print $4}')" )
       	done 
	echo "$(echo ${sc[*]} | sed -e 's/ /,/g' )" >> $outfile
done

echo "" >> $outfile 
echo "perf" >> $outfile 
for f in "${tests[@]}"; do #for each benchmark
	echo "$f" >> $outfile
	ev_row=$(echo "stats,$(echo ${p_events[*]} | sed -e 's/ /,/g' )") #row with the events
	echo $ev_row >> $outfile
	for g in "${methods[@]}"; do  #for each method
		sc=()
		sc+=("$g") #label the row
		for p in "${p_events[@]}"; do
			if [ ! -z "$(grep $p ${f}_${g}_*_perf )" ]; then
			       	sc+=( "$(grep $p ${f}_${g}_*_perf | grep -v "Add" | sed -e"s/,//g" -e "s/$p//g" -e "s/\s\s*//g" )" ) #could find event in file
			else
				sc+=( "n/a" )
			fi
		done
		echo "$(echo ${sc[*]} | sed -e 's/ /,/g' )" >> $outfile
       	done 
	#remaining events stats: grep -Eo "name=[a-zA-Z_0-9=]*/" | sed -e 's/name=//g' -e 's/\///g'
	#rem=$(echo "$perf_command" | grep -Eo "name=[a-zA-Z_0-9=]*/" | sed -e 's/name=//g' -e 's/\///g')
	echo "" >> $outfile #construct a separate table

done

