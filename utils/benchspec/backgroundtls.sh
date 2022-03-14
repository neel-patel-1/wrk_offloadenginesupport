#!/bin/bash
remote_host=n869p538@pollux.ittc.ku.edu
remote_spec=/usr/local/cpu2017/bin/runcpu
spec_params="--config=testConfig.cfg --copies=1 -o txt --fakereport 525.x264_r"
run=${1} #type of test
clients=${2} #number of client threads

#start client threads
if [ "$run" = "https" ]; then
	echo "https benchmark -- $clients threads"
elif [ "$run" = "http" ]; then
	echo "http benchmark -- $clients threads"
elif [ "$run" = "https offload" ]; then
	echo "https offload -- $clients threads"
elif [ "$run" = "httpsendfile" ]; then
	echo "http with sendfile benchmark -- $clients threads"
else
	echo "benchmark -- no clients"
fi


#start 525 test
res_path=$(ssh ${remote_host} ${remote_spec} ${spec_params} | grep -e 'format: Text' | awk '{print $4}')

#get rate from 525 test
echo "reading results from : $res_path"
ssh ${remote_host} "/bin/cat $res_path" | sed -n 's/525.x264_r\s*[0-9][0-9]*\s*\([0-9][0-9]*\)\s*[0-9][0-9]*\s*\*/\1/p' | head -n 1
