#!/bin/bash
export WRK_ROOT=$(pwd)
export resdir=$WRK_ROOT/results
[ ! -d "$resdir" ] && mkdir $resdir
export wrk_output=$WRK_ROOT/wrk_files
[ ! -d "$wrk_output" ] && mkdir $wrk_output


echo -n "" > $resdir/${1}_${2}s.csv
chmod 0666 $resdir/${1}_${2}s.csv
echo "Size(GB),Read(GB),Read/S(GB)" >> $resdir/${1}_${2}s.csv
for s in $wrk_output/${1}_${2}_*.wrk
do
	magn=$(echo "$s" | grep -Eo '[0-9]*[A-Z]' | tail -n 1 | grep -Eo '[A-Z]')
	size=$(echo "$s" | grep -Eo '[0-9]*[A-Z]' | tail -n 1 | grep -Eo '[0-9]*')
	if [[ "$magn" = "M" ]]; then
		size=$(python3 -c "print(float(${size})*1000)")
	elif [[ "$magn" = "G" ]]; then
		size=$(python3 -c "print(float(${size})*1000000)")
	elif [[ "$magn" = "B" ]]; then
		size=$(python3 -c "print(float(${size})/1000)")
	else
		size=$(python3 -c "print(float(${size}))")
	fi
	echo "writing $1 results for size ${size} KB to ${1}_${2}s.csv"

	#convert total read to MB
	magn="MB"
	magn=$(sed -E -n -e 's/\s*[0-9]* requests in [0-9]*.[0-9]*[sm], ([0-9]*.[0-9]*)(MB|GB|B|KB) read/\2/p' $s)
	tot_read=$(sed -E -n -e 's/\s*[0-9]* requests in [0-9]*.[0-9]*[sm], ([0-9]*.[0-9]*)(MB|GB|B|KB) read/\1\2/p' $s)
	tot_read_num=$(sed -E -n -e 's/\s*[0-9]* requests in [0-9]*.[0-9]*[sm], ([0-9]*.[0-9]*)(MB|GB|B|KB) read/\1/p' $s)

	tot_read_GB=$tot_read_num
	if [[ "$magn" = "MB" ]]; then
		tot_read_GB=$(python3 -c "print(float(${tot_read_num})/1000)")
	elif [[ "$magn" = "KB" ]]; then
		tot_read_GB=$(python3 -c "print(float(${tot_read_num})/1000000)")
	elif [[ "$magn" = "B" ]]; then
		tot_read_GB=$(python3 -c "print(float(${tot_read_num})/1000000000)")
	else
		tot_read_GB=$(python3 -c "print(float(${tot_read_num}))")
	fi
	echo "total read: $tot_read_GB"


	#convert read/sec to GBs
	magn="MB"
	magn=$(sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\2/p' $s)

	read_persec=$(sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1\2/p' $s)
	read_persec_num=$(sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1/p' $s)

	read_persec_GB=$read_persec_num
	if [[ "$magn" = "MB" ]]; then
		read_persec_GB=$(python3 -c "print(float(${read_persec_num})/1000)")
	elif [[ "$magn" = "KB" ]]; then
		read_persec_GB=$(python3 -c "print(float(${read_persec_num})/1000000)")
	elif [[ "$magn" = "B" ]]; then
		read_persec_GB=$(python3 -c "print(float(${read_persec_num})/1000000000)")
	else
		tot_read_GB=$(python3 -c "print(float(${read_persec_num}))")
	fi
	echo "persec read: $read_persec_GB"
	
	echo "$size,$tot_read_GB,$read_persec_GB" >> $resdir/${1}_${2}s.csv
done
