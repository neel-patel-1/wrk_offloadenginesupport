#!/bin/bash
remote_host=n869p538@pollux.ittc.ku.edu
remote_spec=/usr/local/cpu2017/bin/runcpu
remote_cpu=/usr/local/cpu2017
run=${1} #type of test
clients=${2} #number of client threads
servers=${3}
fSize=${4}
copies=${5}
pid=""
spec_params="--config=testConfig.cfg --copies=$copies  -o txt 525.x264_r"

#calc taskset for same spec benchmark pcores
#nginx always gets lower cores
num_spec_cores=9
num_cores=20
task_set="taskset --cpu-list 1-${servers},$((1 + $num_cores))-$(($servers + $num_cores))"
>&2 echo "$task_set"

#start client threads
if [ "$run" = "https" ]; then
	>&2 echo "https benchmark -- $clients threads -- $servers threads -- file size: $fSize"
	./utils/bandwidth_measurement/maximum_tls_throughput.sh 8h $clients $fSize $servers &
	pid=$!
elif [ "$run" = "http" ]; then
	>&2 echo "http benchmark -- $clients threads -- $servers threads -- file size: $fSize"
	./utils/bandwidth_measurement/maximum_http_throughput.sh 8h $clients $fSize $servers &
	pid=$!
elif [ "$run" = "offload" ]; then
	>&2 echo "https offload -- $clients threads -- $servers threads -- file size: $fSize"
	./utils/bandwidth_measurement/maximum_offload_throughput.sh 8h $clients $fSize $servers &
	pid=$!
elif [ "$run" = "httpsendfile" ]; then
	>&2 echo "http with sendfile benchmark -- $clients threads -- $servers threads -- file size: $fSize"
	./utils/bandwidth_measurement/maximum_httpsendfile_throughput.sh 8h $clients $fSize $servers &
	pid=$!
elif [ "$run" = "qtls" ]; then
	>&2 echo "qtls with sendfile benchmark -- $clients threads -- $servers threads -- file size: $fSize"
	./utils/bandwidth_measurement/maximum_qtls_throughput.sh 8h $clients $fSize $servers &
	pid=$!
else
	>&2 echo "benchmark -- no connections "
fi


#choose taskset cores
#start 525 test


res_path=$(ssh ${remote_host} ${task_set} ${remote_spec} ${spec_params} | grep -e 'format: Text' | awk '{print $4}')

>&2 echo "$res_path"
#get rate from 525 test
>&2 echo "reading results from : $res_path"
rate=$(ssh ${remote_host} "/bin/cat $res_path" | sed -n 's/525.x264_r\s*[0-9][0-9]*\s*\([0-9][0-9]*\)\s*\([0-9][0-9]*.*[0-9]*\)\s*\*/\1 \2/p' | head -n 1)
echo $rate


#kill clients
kill -s 2 $pid
ps aux | grep './wrk' | awk '{print $2}' | xargs sudo kill -s 2

#clean up results directory
scp ${remote_host}:${res_path} remote_res
ssh ${remote_host} "rm -rf ${remote_cpu}/result/*"

