#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

[ "$duration" = "" ] && duration=10
[ "$numCores" = "" ] && numCores=10
[ -z "$fSize" ] && echo "no file size selected" && exit
[ -z "$numServerCores" ] && echo "no server cores selected" && exit
[ -z "$numCores" ] && echo "no server cores selected" && exit
[ "$prepend" = "" ] && prepend=$(date +%T)

[ "$prepend" = "" ] && prepend=$(date +%T)
[ ! -d "${wrk_output}/${prepend}" ] && mkdir -p ${wrk_output}/${prepend}

wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/${prepend}/axdimm #allow callers to prepend a directory

[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  stop ${numServerCores}
[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  axdimm ${numServerCores}

echo -n "" > ${outfile}
for j in `seq 0 $(( $numCores - 1 ))`; do
	# write transfer per sec
	#echo "Core ${j} initialized"
	${WRK_ROOT}/utils/bandwidth_measurement/offload_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
${WRK_ROOT}/utils/parseOutput/sum_core_throughput.sh $outfile
