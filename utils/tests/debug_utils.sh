#!/bin/bash
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src


debug(){
	[ -z "$1" ] && echo "[FATAL]: debug output called with no function argument"
	>&2 echo "[DEBUG]: $1" 
}
