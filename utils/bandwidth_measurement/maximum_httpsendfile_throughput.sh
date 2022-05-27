#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src
[ "$duration" = "" ] && duration=10
[ "$fSize" = "" ] && echo "no file size selected" && exit
[ "$numCores" = "" ] && echo "no client cores selected" && exit
[ -z "$numCores" ] && echo "no server cores selected" && exit
[ "$prepend" = "" ] && prepend=$(date +%T)

[ "$prepend" = "" ] && prepend=$(date +%T)
[ ! -d "${wrk_output}/${prepend}" ] && mkdir -p ${wrk_output}/${prepend}

wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/$prepend/httpsendfile

#stop remote nginx
[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  stop ${numServerCores}
[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  httpsendfile ${numServerCores}
#tls config contains sendfile directive

echo -n "" > $outfile
for j in `seq 1 ${numCores}`; do
	# write transfer per sec
	#echo "Core ${j} initialized"
	${UTIL_DIR}/bandwidth_measurement/httpsendfile_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
${UTIL_DIR}/parseOutput/sum_core_throughput.sh $outfile


