#!/bin/bash
outfile=$1

declare -A div=( ["us"]=.000001 ["ms"]=.001 )

avg=$(grep Latency $outfile | awk '{printf("%f", $2);}' )
stdev=$(grep Latency $outfile | awk '{printf("%f", $3);}' )

units=( $(grep Latency $outfile | grep -Eo '.s' | head -n 2 | tr '\n' ' ' )) #| sed -e 's/^/"/g' -e 's/ $/"/g' -e 's/ /" "/g' ) )
conv=$(python -c "print ( $avg * (${div[${units[0]}]#*:} / ${div[${units[1]}]#*:}) )")
pre=$(python -c "print ($conv + ($stdev * 2.3263))")
post=$(python -c "print ( $pre * (${div[${units[1]}]#*:} / ${div[${units[0]}]#*:}) )")
#avg,99th

echo $avg${units[0]},$post${units[0]}

