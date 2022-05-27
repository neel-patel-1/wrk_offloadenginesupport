#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

[ "$duration" = "" ] && duration=10
[ -z "$fSize" ] && echo "no file size selected" && exit
[ -z "$numServerCores" ] && echo "no server cores selected" && exit
[ -z "$numCores" ] && echo "no client cores selected" && exit
[ "$prepend" = "" ] && prepend=$(date +%T)

[ "$prepend" = "" ] && prepend=$(date +%T)
[ ! -d "${wrk_output}/${prepend}" ] && mkdir -p ${wrk_output}/${prepend}

wrk_output=/home/n869p538/wrk_offloadenginesupport/wrk_files
outfile=${wrk_output}/${prepend}/qtls #allow callers to prepend a directory

#stop remote nginx
[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  stop ${numServerCores}
[ "${remote_user}" != "" ] && ssh ${remote_user} ${remote_nginx_start}  qtls ${numServerCores} 

echo -n "" > $outfile
for j in `seq 0 $((numCores - 1))`; do
	# write transfer per sec
	# echo "Core ${j} initialized"
	${QTLS_TEST_DIR}/qtls_core_throughput.sh ${j} ${duration} ${fSize} ${outfile} &
done

#total bandwidth report
wait
${WRK_ROOT}/utils/parseOutput/sum_core_throughput.sh $outfile
exit
[ -z "$( cat $outfile )" ] && echo "REMOTE QAT ERROR" && \
	read  -n 1 -p "Rebuild Remote QAT:" rebuild
[ "$rebuild" = "y" ] && ssh ${remote_user} sudo rm -rf ${remote_root}/qtls \
       	&& ssh ${remote_user} ${remote_scripts}/qtls/build_qtls.sh \
	&& read  -n 1 -p "Rerun with new build?" rerun
[ "$rerun" = "y" ] && ${band_dir}/maximum_qtls_throughput.sh

