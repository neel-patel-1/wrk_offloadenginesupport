#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

if [ ! -z "${outdir}" ];then
       outfile=${outdir}/core_${core}_wrk
else
       outfile=${WRK_OUT}/core_${core}_wrk
fi

declare -A div=( ["us"]=.000001 ["ms"]=.001 ["m"]=60 ["h"]=3600 )

tee $outfile <&0 1>/dev/null
bandwidth=$(sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1\2/p' $outfile)
avg=$(grep Latency $outfile | awk '{printf("%f", $2);}' )
stdev=$(grep Latency $outfile | awk '{printf("%f", $3);}' )

units=( $(grep Latency $outfile | grep -Eo '.s' | head -n 2 | tr '\n' ' ' )) #| sed -e 's/^/"/g' -e 's/ $/"/g' -e 's/ /" "/g' ) )
conv=$(python -c "print ( $avg * (${div[${units[0]}]#*:} / ${div[${units[1]}]#*:}) )")
pre=$(python -c "print ($conv + ($stdev * 2.3263))")
post=$(python -c "print ( $pre * (${div[${units[1]}]#*:} / ${div[${units[0]}]#*:}) )")
#avg,99th

echo $bandwidth,$avg${units[0]},$post${units[0]}

