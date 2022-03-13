#!/bin/bash
duration=${2}
core=${1}
fSize=${3}
out_file=${4}

./utils/primitives/httpCore.sh ${core} ${duration} ${fSize} | \
./utils/parseOutput/write_core_throughput.sh \
>> ${out_file}

#caller runs script in background
