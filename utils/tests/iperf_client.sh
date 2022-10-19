#!/bin/bash
#set root directory
export WRK_ROOT=/home/n869p538/wrk_offloadenginesupport
source $WRK_ROOT/vars/env.src

[ ! -f "${iperf_dir}/newreq.pem" ] || [ ! -f "${iperf_dir}/key.pem" ] && openssl req -x509 -newkey rsa:2048 -keyout ${iperf_dir}/key.pem -out ${iperf_dir}/newreq.pem -days 365 -nodes
cd ${iperf_dir}

>&2 echo "[info] AXDIMM iperf client..."
sudo env \
OPENSSL_ENGINES=$AXDIMM_ENGINES \
LD_LIBRARY_PATH=$AXDIMM_OSSL_LIBS:$AXDIMM_DIR/lib \
$offload_iperf --tls=qat -c ${remote_ip} -t 60 -i 5 -y C
