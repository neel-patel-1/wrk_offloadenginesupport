### Nginx Workload Experiments
* Corresponds to figures 11 and 12 in [SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact](https://www.hpca-conf.org/2024)<br>

#### Setting up Cloudlab Instances:
To ease reproduction we have created a cloudlab environment and setup closely matching the server configuration used in the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`

Following the instructions below will provision a cloudlab instance in which the SPEC 2017 and (de)compression workloads
from the paper will be executed. For more information, refer to [`SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`](https://www.hpca-conf.org/2024)

* allocate a cloudlab instance using the genilib script provided in this repo
	* Create a cloudlab account if needed
	* Navigate to `Experiments`, then `Create Experiment Profile`, and upload `nginx_workload.profile`

#### Artifact Evaluation Instructions:
To ease reproducibility for our artifact evaluators we have provided on-premise access to the servers used to generate the original nginx workload results from the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`
* please reach out to the authors if there are any further questions regarding accessing our on-premise hosts

### Compressed File Server Setup and Workload Generation
* dut setup: (e.g., run on pollux from `async_nginx_build` directory)
```sh
./scripts/configure.sh
make default # build baseline nginx

# setup server with files
./scripts/L5P_DRAM_Experiments/setup_server.sh 16K
./scripts/L5P_DRAM_Experiments/setup_server.sh 4K

# gzip build
cd nginx_compress_emul
./default_build.sh
# gzip emulation build
./emul_build.sh
cd ..
# qat build -- assumes QAT c62x series PCIe adaptor installed
make qtls
```

* workload generation and result collection
```sh
cd client_ossls
./build_1_1_1f.sh
cd ../client_wrks
make default_wrk
# modify /home/n869p538/wrk_offloadenginesupport/vars/env.src pollux remote config to dut hostname and ip

mkdir gzip_rpc
cd gzip_rpc
source /home/n869p538/wrk_offloadenginesupport/utils/tests/test_funcs.sh;
compress_var_file_sizes # max RPS Compression test

source /home/n869p538/wrk_offloadenginesupport/utils/tests/parse_utils.sh;
parse_many_multi_file_compress # parse results to stdout
# Normalize to accel-gzip to http-gzip for RPS comparison

cd ..
git submodule update --init wrk2
cd wrk2
make -j
cd ..
mkdir gzip_membw_cpu
cd gzip_membw_cpu
source /home/n869p538/wrk_offloadenginesupport/utils/tests/test_funcs.sh;
multi_many_compression_file_const_test # constant RPS membw and CPU Util test

source /home/n869p538/wrk_offloadenginesupport/utils/tests/parse_utils.sh;
parse_many_file_compress_const # output csv to stdout
# Normalize to accel-gzip to http-gzip for mem-bw and cpu-util comparison
```

### TLS-Encrypted File Server Experiments
* dut setup: (e.g., run on pollux from `async_nginx_build` directory)
```sh
./scripts/configure.sh
make default # build baseline nginx
make axdimm # build SmartDIMM-Accelerated nginx
make qtls # build QAT-Accelerated nginx
make ktls # build SmartNIC-Accelerated TLS nginx


# setup server with files
./scripts/L5P_DRAM_Experiments/setup_server.sh 16K
./scripts/L5P_DRAM_Experiments/setup_server.sh 4K
```

* workload generation and result collection
```sh
# build required openssl libs
cd client_ossls
./build_1_1_1f.sh

# build workload generators
cd ../client_wrks
make default_wrk
make engine_wrk
make ktls_wrk
git submodule update --init wrk2
cd wrk2
make -j
cd ..

# build SmartDIMM Libraries
cd ../async_nginx_build
make axdimm

# modify /home/n869p538/wrk_offloadenginesupport/vars/env.src pollux remote config to dut hostname and ip
source /home/n869p538/wrk_offloadenginesupport/utils/tests/test_funcs.sh;
multi_many_file_var # max RPS test

source /home/n869p538/wrk_offloadenginesupport/utils/tests/parse_utils.sh;
parse_many_multi_file

cd ..

source /home/n869p538/wrk_offloadenginesupport/utils/tests/test_funcs.sh; 
multi_many_constrps_var_files # tls membw cpu test

source /home/n869p538/wrk_offloadenginesupport/utils/tests/parse_utils.sh;
parse_many_multi_file_const


```


#### Issues:
```
[DEBUG]: capture_core_mt_async: 16 threads with 1024 clients started ...                                                      [6/1940]
[6] 2694066      
unable to initialize SSL using Offload Engine 
140484302236544:error:25066067:DSO support routines:dlfcn_load:could not load the shared library:crypto/dso/dso_dlfcn.c:118:filename(/
home/n869p538/wrk_offloadenginesupport/async_nginx_build/axdimm/openssl/lib/engines-1.1/qatengine.so): /home/n869p538/wrk_offloadengin
esupport/async_nginx_build/axdimm/openssl/lib/engines-1.1/qatengine.so: cannot open shared object file: No such file or directory     
140484302236544:error:25070067:DSO support routines:DSO_load:could not load the shared library:crypto/dso/dso_lib.c:162:              
140484302236544:error:260B6084:engine routines:dynamic_load:dso not found:crypto/engine/eng_dyn.c:414:
140484302236544:error:2606A074:engine routines:ENGINE_by_id:no such engine:crypto/engine/eng_list.c:334:id=qatengine
```
* Recompile client offload engine:
```
cd async_nginx_build
make axdimm
```


```
[DEBUG]: ktls_mt_core: /home/n869p538/wrk_offloadenginesupport/client_wrks/autonomous-asplos21-artifact/wrk/wrk -t16 -c1024  -d10  https://192.168.2.2:443/na
-bash: /home/n869p538/wrk_offloadenginesupport/client_wrks/autonomous-asplos21-artifact/wrk/wrk: No such file or directory
[5]   Exit 127                ${1}_mt_core $2 $3 $4 $5 $( getport $1 ) ${7} $9 > $8
```

* compile client_wrk for ktls