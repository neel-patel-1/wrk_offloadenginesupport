#!/bin/bash
duration=${1}
numCores=${2}
fSize=${3}
numServerCores=${4}
wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/httpsendfile_${1}_${fSize}.per_core_throughput

#stop remote nginx
ssh ${remote_user} ${remote_nginx_start}  -s stop ${numServerCores}
ssh ${remote_user} ${remote_nginx_start}  tls ${numServerCores}
#tls config contains sendfile directive

echo -n "" > $wrk_output/httpsendfile_${duration}_${fSize}.per_core_throughput
for j in `seq 1 ${numCores}`; do
	# write transfer per sec
	#echo "Core ${j} initialized"
	./utils/bandwidth_measurement/httpsendfile_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
./utils/parseOutput/sum_core_throughput.sh $outfile

