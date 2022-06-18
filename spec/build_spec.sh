#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source ${WRK_ROOT}/vars/env.src
[ ! -d "spec_mnt" ] && mkdir spec_mnt
[ ! -d "cpu_2017" ] && mkdir cpu_2017
if [ ! -f "cpu2017-1_0_5.iso" ]; then
	echo "attempting to get spec from remote host"
	scp ${remotespeciso} cpu2017-1_0_5.iso
	[ ! -f "cpu2017-1_0_5.iso" ] && echo "could not obtain spec" && exit
fi
if [ ! -f "cpu_2017/bin/runcpu" ]; then
	sudo mount -t iso9660 -o ro,exec,loop cpu2017-1_0_5.iso spec_mnt
	cd spec_mnt && ./install.sh -d ../cpu_2017
	cd ../
fi
cp default.cfg cpu_2017/config
[ -d "spc_mnt" ] && sudo rm -rf spec_mnt

