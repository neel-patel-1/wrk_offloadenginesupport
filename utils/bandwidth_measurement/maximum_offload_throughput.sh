#!/bin/bash
duration=${1}
numCores=${2}
fSize=${3}
numServerCores=${4}
wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/offload_${1}_${fSize}.per_core_throughput

#stop remote nginx
ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh -s stop ${numServerCores}
ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh tlso ${numServerCores}

echo -n "" > $wrk_output/offload_${duration}_${fSize}.per_core_throughput
for j in `seq 1 ${numCores}`; do
	# write transfer per sec
	#echo "Core ${j} initialized"
	./utils/bandwidth_measurement/offload_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
./utils/parseOutput/sum_core_throughput.sh $outfile


