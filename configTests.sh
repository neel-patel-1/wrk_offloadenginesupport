#!/bin/bash

#stop remote nginx
ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh -s stop
ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh tls

#config 1 tests
./wrkCli.sh tls 10 #give break
./wrkCli.sh tls ${1} #gen 60s
./utils/genCSV.sh tls ${1}
./wrkCli.sh tcpsendfile ${1}
./utils/genCSV.sh tcpsendfile ${1}

#switch to second config

ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh -s stop
ssh n869p538@pollux.ittc.ku.edu /home/n869p538/nginx-1.20.1/nginx_qat.sh tlso

#config 2 tests
./wrkCli.sh tlso 10 #give break
./wrkCli.sh tlso ${1}
./utils/genCSV.sh offload ${1}
./wrkCli.sh tcp ${1}
./utils/genCSV.sh tcp ${1}
