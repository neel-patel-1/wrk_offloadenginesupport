#!/bin/bash
duration=${1}
numCores=${2}
fSize=${3}
numServerCores=${4}
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/qtls_${1}_${fSize}.per_core_throughput

#stop remote nginx
ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh -s stop ${numServerCores}
ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh qtls ${numServerCores}

echo -n "" > $outfile
for j in `seq 1 ${numCores}`; do
	# write transfer per sec
	#echo "Core ${j} initialized"
	${QTLS_TEST_DIR}/qtls_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} $(( $j % 10 + 2 )) &
done

#total bandwidth report
wait
${WRK_ROOT}/utils/parseOutput/sum_core_throughput.sh $outfile


