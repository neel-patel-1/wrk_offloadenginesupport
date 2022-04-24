export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

export prepend="just_axdimm_separate_$(date +%T)"
export outdir=${WRK_ROOT}/spec_res/test_ocperf
[ ! -d "$outdir" ] && mkdir -p $outdir
export outfile=$outdir/test.csv


declare -a p_events=( "llc_misses.mem_read" "llc_misses.mem_write" "llc_misses.pcie_read" "llc_misses.pcie_write" "UNC_M_CAS_COUNT.WR" )

[ ! -z "$p_events" ] && p_com="stat -e $(echo ${p_events[*]} | sed -e 's/^/"/g' -e 's/ /" -e "/g' -e 's/$/"/g')"
echo $p_com
# start remote ocperf on a given command

[ ! -z "$p_events" ] && ssh ${remote_host} ${remote_ocperf} ${p_com} ${task_set} 1,21 ls  2| tee $outfile  

#[ ! -z "$p_events" ] && ssh ${remote_host} ${remote_ocperf} ${p_com} ${task_set} 8,28 ${remote_spec} ${spec_params} 1>spec_out 2>${WRK_ROOT}/spec_res/just_axdimm_separate_14\:09\:40/505.mcf_r_axdimm_0\,20-19\,39_perf &
