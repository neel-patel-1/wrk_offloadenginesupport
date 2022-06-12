#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/environment.src

## SWITCH UTILS ##

ports_up(){
	ssh ${tna_host} "${tna_sde}/run_bfshell.sh -f ${tna_sde}/myPrograms/port_setup.bfsh"
}
start_default_switch(){
	#TODO allow running on any tfa switch with an sde installation
	ssh ${tna_host} "${tna_sde}/run_bfshell.sh -f ${tna_sde}/myPrograms/port_setup.bfsh"
	ssh ${tna_host} "${tna_sde}/run_bfshell.sh -b ${tna_sde}/myPrograms/l2_setup.py"
}

start_drop_switch(){
	ssh ${tna_host} "${tna_sde}/run_bfshell.sh -f ${tna_sde}/myPrograms/port_setup.bfsh"
	ssh ${tna_host} "${tna_sde}/run_bfshell.sh -b ${tna_sde}/myPrograms/drop_setup.py"
}

# Params: 1- name of program to load on switch (no .p4 extension)
start_switchd(){
	if [ -z "$1" ]; then echo "${FUNCNAME[0]}: missing params" && exit; fi
	echo -n "" > switch_out
	ssh -f ${tna_host} "${tna_sde}/run_switchd.sh -p $1" >> switch_out
	tail -f switch_out | sed '/bf_switchd: initialized/ q'
	echo "switch startup completed"
}

kill_switchd(){
	ssh ${tna_host} "ps aux | grep switchd | awk '{print \$2}' | xargs kill -KILL"
}

compile_switch(){
	[ -z "$1" ] && echo "${FUNCNAME[0]}: missing params"
	ssh ${tna_host} <<runconfig
		${tna_sde}/pkgsrc/p4-build/configure \
 		--prefix=${tna_sde}/install \
		--with-p4c=/usr/system/src/bf-sde-9.4.0/pkgsrc/p4-compilers/p4c-9.4.0.x86_64/bin/bf-p4c \
		--with-tofino \
		P4_NAME=${1} \
		P4_PATH=${tna_sde}/myPrograms/${1}.p4 \
		P4_VERSION=p4-16 \
		P4_ARCHITECTURE=tna
		make
		make install
runconfig
}

#param: 1-thresh (number of packets passing through /1024)
change_drop_thresh(){
	ssh ${tna_host} <<runsed
		sed -i -e "/const DropReg_t thresh=[0-9][0-9]*;/d" \
		-e "/\/\*Threshhold\*\//a const DropReg_t thresh=${1};" \
		${tna_sde}/myPrograms/myL2Drop.p4
runsed
}

#param: 1-thresh (number of packets passing through /1024)
rebuild_drop(){
	[ -z "$1" ] && echo "${FUNCNAME[0]}: missing params"
	kill_switchd
	change_drop_thresh $1
	compile_switch myL2Drop
	start_switchd myL2Drop
	start_drop_switch
}

#start simple l2 forwarding switch
rebuild_l2(){
	kill_switchd
	compile_switch mySimpleL2
	start_switchd mySimpleL2
	start_default_switch
}


# 1 - size of file to check for in nginx root dirs
# 2 - remote host
# 3 - remote nginx_script directory
remote_file(){
	ssh ${2} "${3} ${1}"
}

# 1 - method to pass to remote nginx
# 2 - num server cores
start_remote_nginx(){
	ssh ${remote_host} $remote_nginx_start $1 $2 > /dev/null
}
