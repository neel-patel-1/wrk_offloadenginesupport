#!/bin/bash

mask=""
occupied=5
num_spec_cores=1
num_cores=20
for i in `seq 1 ${occupied}`
do
	mask1+="0"
	mask2+="0"
done
for i in `seq $(($occupied + 1)) $(($num_spec_cores+$occupied))`
do
	mask1+="1"
	mask2+="1"
done
for i in `seq $(($num_spec_cores + $occupied + 1)) $num_cores`
do
	mask1+="0"
	mask2+="0"
done
task_set="taskset --cpu-list ${occupied}-$(($occupied + $num_spec_cores - 1)) $(($occupied + $num_cores))-$(($num_cores + occupied + $num_spec_cores - 1))"

echo "$task_set"
