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
outfile=${wrk_output}/${prepend}/https


#stop remote nginx
ssh ${remote_user} ${remote_nginx_start}  stop ${numServerCores}
ssh ${remote_user} ${remote_nginx_start}  https ${numServerCores}

echo -n "" > $outfile
for j in `seq 1 ${numCores}`; do
	# write transfer per sec
	#echo "Core ${j} initialized"
	./utils/bandwidth_measurement/tls_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
${WRK_ROOT}/utils/parseOutput/sum_core_throughput.sh $outfile


