#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

if [ ! -z "${outdir}" ];then
       outfile=${outdir}/core_${core}_wrk
else
       outfile=${WRK_OUT}/core_${core}_wrk
fi

tee $outfile | sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1 \2/p' <&0
