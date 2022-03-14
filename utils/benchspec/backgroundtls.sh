#!/bin/bash
remote_host=n869p538@pollux.ittc.ku.edu
remote_spec=/usr/local/cpu2017/bin/runcpu
remote_cpu=/usr/local/cpu2017
spec_params="--config=testConfig.cfg --copies=1 -o txt --fakereport 525.x264_r"
run=${1} #type of test
clients=${2} #number of client threads
servers=${3}
fSize=${4}
pid=""

#start client threads
if [ "$run" = "https" ]; then
	echo "https benchmark -- $clients threads -- $servers threads -- file size: $fsize"
	./utils/bandwidth_measurement/maximum_tls_throughput.sh 8h $clients $fSize $servers &
	pid=$!
elif [ "$run" = "http" ]; then
	echo "http benchmark -- $clients threads -- $servers threads -- file size: $fsize"
	./utils/bandwidth_measurement/maximum_http_throughput.sh 8h $clients $fSize $servers &
	pid=$!
elif [ "$run" = "offload" ]; then
	echo "https offload -- $clients threads -- $servers threads -- file size: $fsize"
	./utils/bandwidth_measurement/maximum_offload_throughput.sh 8h $clients $fSize $servers &
	pid=$!
elif [ "$run" = "httpsendfile" ]; then
	echo "http with sendfile benchmark -- $clients threads -- $servers threads -- file size: $fsize"
	./utils/bandwidth_measurement/maximum_httpsendfile_throughput.sh 8h $clients $fSize $servers &
	pid=$!
else
	echo "benchmark -- no connections "
fi


#start 525 test
res_path=$(ssh ${remote_host} ${remote_spec} ${spec_params} | grep -e 'format: Text' | awk '{print $4}')

#get rate from 525 test
echo "reading results from : $res_path"
rate=$(ssh ${remote_host} "/bin/cat $res_path" | sed -n 's/525.x264_r\s*[0-9][0-9]*\s*\([0-9][0-9]*\)\s*[0-9][0-9]*\s*\*/\1/p' | head -n 1)
rate+=" points"
echo $rate


#kill clients
kill -s 2 $pid
ps aux | grep './wrk' | awk '{print $2}' | xargs sudo kill -s 2

#clean up results directory
scp ${remote_host}:${res_path} remote_res
ssh ${remote_host} "rm -rf ${remote_cpu}/result/*"
