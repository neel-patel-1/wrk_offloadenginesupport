#!/bin/bash

dur=${1}

#get size in kilobytes ++ populate this row first
declare -a sizes=("4K" "16K" "64K" "256K" )
#declare -a cons=("https" "offload" "http" "http + sendfile")
declare -a cons=("tls" "offload" "tcp" "tcpsendfile")

export WRK_ROOT=$(pwd)
export resdir=$WRK_ROOT/results
export csv_resdir=$WRK_ROOT/csv_results
[ ! -d "$csv_resdir" ] && mkdir $csv_resdir

echo -n "" > ${csv_resdir}/${dur}s_chart.csv
echo ",4,16,64,256" >> ${csv_resdir}/${dur}s_chart.csv
#echo ",4,16,64,256" 
for i in "${cons[@]}"
do
	conGBPS=" "
	for j in "${sizes[@]}"
	do
		#echo "${resdir}/${j}_${dur}s.csv"
		magn=$(echo "$j" | grep -Eo '[0-9]*[A-Z]' | tail -n 1 | grep -Eo '[A-Z]*')
		size=$(echo "$j" | grep -Eo '[0-9]*[A-Z]' | tail -n 1 | grep -Eo '[0-9]*')
		if [[ "$magn" = "M" ]]; then
			size=$(python3 -c "print(float(${size})*1000)")
		elif [[ "$magn" = "G" ]]; then
			size=$(python3 -c "print(float(${size})*1000000)")
		elif [[ "$magn" = "B" ]]; then
			size=$(python3 -c "print(float(${size})/1000)")
		else
			size=$(python3 -c "print(float(${size}))")
		fi

		echo  "writing $i connection ${size}KB to ${csv_resdir}/${dur}s_chart.csv"
		line=$(grep "^$size," results/${i}_${dur}s.csv)
		#echo "$line"
		GBPS=$(echo "$line" | awk -F',' '{print $3}')
		GB=$(echo "$line" | awk -F',' '{print $2}')
		conGBPS="$conGBPS,${GBPS}"
	done
	#echo  "${i},$(echo "$conGBPS" | sed 's/^ ,//')" 
	echo  "${i},$(echo "$conGBPS" | sed 's/^ ,//')" >> ${csv_resdir}/${dur}s_chart.csv
done
