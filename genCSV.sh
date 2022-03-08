#!/bin/bash
for s in ${1}*.wrk
do
	tot_read=$(sed -E -n -e 's/\s*[0-9]* requests in [0-9]*.[0-9]*s, ([0-9]*.[0-9]*)(MB|GB|B|KB) read/\1\2/p' $s)
	read_persec=$(sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1\2/p' $s)
	echo "$tot_read"
	echo "$read_persec"

done
