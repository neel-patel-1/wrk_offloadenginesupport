#!/bin/bash
duration=${2}
core=${1}
fSize=${3}
out_file=${4}
sub=${5}

${QTLS_TEST_DIR}/qtlsCore.sh ${core} ${duration} ${fSize} | \
${WRK_ROOT}/utils/parseOutput/write_core_throughput.sh \
>> ${out_file}

#caller runs script in background
