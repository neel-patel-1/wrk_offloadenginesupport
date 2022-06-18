#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
duration=${2}
export core=${1}
fSize=${3}
out_file=${4}

${UTIL_DIR}//primitives/ktls_core.sh ${core} ${duration} ${fSize} | \
${UTIL_DIR}//parseOutput/write_core_throughput.sh \
>> ${out_file}

#caller runs script in background

