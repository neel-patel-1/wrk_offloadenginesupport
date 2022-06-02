#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

[ "$duration" = "" ] && duration=10
[ -z "$fSize" ] && echo "no file size selected" && exit
[ -z "$numServerCores" ] && echo "no server cores selected" && exit
[ -z "$numCores" ] && echo "no server cores selected" && exit
[ "$prepend" = "" ] && prepend=$(date +%T)

[ "$prepend" = "" ] && prepend=$(date +%T)
[ ! -d "${wrk_output}/${prepend}" ] && mkdir -p ${wrk_output}/${prepend}

wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/${prepend}/ktls #allow callers to prepend a directory

[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  stop ${numServerCores}
[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  ktls ${numServerCores}

ssh ${remote_user} sudo ethtool -K ${remote_net_dev} tls-hw-tx-offload on tls-hw-rx-offload on
sudo ethtool -K ${local_net_dev} tls-hw-tx-offload on tls-hw-rx-offload on

echo -n "" > ${outfile}
for j in `seq 0 $(( $numCores - 1 ))`; do
	# write transfer per sec
	${UTIL_DIR}/bandwidth_measurement/tls_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
${WRK_ROOT}/utils/parseOutput/sum_core_throughput.sh $outfile

