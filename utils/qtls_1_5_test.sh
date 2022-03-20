#!/bin/bash

export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

for i in ${SPEC_DIR}/enum*
do
	$i
done

${PARSE_DIR}/spec_rate_chart_same.sh 1
${PARSE_DIR}/spec_rate_chart_same.sh 5
${PARSE_DIR}/spec_rate_chart_separate.sh 1
${PARSE_DIR}/spec_rate_chart_separate.sh 5
${PARSE_DIR}/spec_speed_separate_chart.sh 1
${PARSE_DIR}/spec_speed_separate_chart.sh 5
${PARSE_DIR}/spec_speed_same_chart.sh 1
${PARSE_DIR}/spec_speed_same_chart.sh 5
