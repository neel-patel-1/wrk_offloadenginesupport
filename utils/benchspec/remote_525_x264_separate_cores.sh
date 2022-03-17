#!/bin/bash
remote_host=n869p538@pollux.ittc.ku.edu
remote_spec=/usr/local/cpu2017/bin/runcpu
remote_cpu=/usr/local/cpu2017

servers=${1}
num_spec_cores=$2
copies=${3}
spec_start_core=$((servers + 1))
num_cores=20
task_set="taskset --cpu-list ${spec_start_core}-$(($spec_start_core + $num_spec_cores - 1)),$(($spec_start_core + $num_cores))-$(($num_cores + spec_start_core + $num_spec_cores - 1))"
spec_params="--config=testConfig.cfg --copies=$copies  -o txt 525.x264_r"

ssh ${remote_host} ${task_set} ${remote_spec} ${spec_params} #| grep -e 'format: Text' | awk '{print $4}'
