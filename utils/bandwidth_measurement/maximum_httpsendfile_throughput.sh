#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
[ "$duration" = "" ] && duration=10
[ "$numCores" = "" ] && numCores=10
[ "$fSize" = "" ] && fSize=256K
[ "$numServerCores" = "" ] && numServerCores=10
[ "$prepend" = "" ] && prepend=$(date +%T)

[ "$prepend" = "" ] && prepend=$(date +%T)
[ ! -d "${wrk_output}/${prepend}" ] && mkdir -p ${wrk_output}/${prepend}

wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/$prepend/httpsendfile

#stop remote nginx
ssh ${remote_user} ${remote_nginx_start}  stop ${numServerCores}
ssh ${remote_user} ${remote_nginx_start}  http_sendfile ${numServerCores}
#tls config contains sendfile directive

echo -n "" > $wrk_output/httpsendfile_${duration}_${fSize}.per_core_throughput
for j in `seq 1 ${numCores}`; do
	# write transfer per sec
	#echo "Core ${j} initialized"
	${UTIL_DIR}/bandwidth_measurement/httpsendfile_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
${UTIL_DIR}/parseOutput/sum_core_throughput.sh $outfile


