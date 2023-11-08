### Compressed File Server Experiments
* dut setup: (e.g., run on pollux)
* from async_nginx_build
```
./scripts/configure.sh
make default # build baseline nginx

# setup server with compressed files
./scripts/L5P_DRAM_Experiments/setup_server.sh 16K
./scripts/L5P_DRAM_Experiments/setup_server.sh 4K

# gzip build
cd nginx_compress_emul
./default_build.sh
# gzip emulation build
./emul_build.sh



```

* multi-many file test for gzip
```
cd client_ossls
./build_1_1_1f.sh
cd ../client_wrks
make default_wrk
# modify /home/n869p538/wrk_offloadenginesupport/vars/env.src pollux remote config to dut hostname and ip
source /home/n869p538/wrk_offloadenginesupport/utils/tests/test_funcs.sh;
multi_many_file_var_gzip # max RPS Compression test

source /home/n869p538/wrk_offloadenginesupport/utils/tests/parse_utils.sh;
parse_many_file_compress

cd ..
git submodule update --init wrk2
cd wrk2
make -j
cd ..
multi_many_file_var_gzip_const # constant RPS membw and CPU Util test

source /home/n869p538/wrk_offloadenginesupport/utils/tests/parse_utils.sh;
parse_many_file_compress_const # output csv to stdout

```

### Nginx Workload Experiments
* Corresponds to figures 11 and 12 in [SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact](https://www.hpca-conf.org/2024)<br>

#### Setting up Cloudlab Instances:
To ease reproduction we have created a cloudlab environment and setup closely matching the server configuration used in the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`

Following the instructions below will provision a cloudlab instance in which the SPEC 2017 and (de)compression workloads
from the paper will be executed. For more information, refer to [`SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`](https://www.HPCA 56.org/)

* allocate a cloudlab instance using the genilib script provided in this repo
	* Create a cloudlab account if needed
	* Navigate to `Experiments`, then `Create Experiment Profile`, and upload `nginx_workload.profile`

#### Artifact Evaluation Instructions:
To ease reproducibility for our artifact evaluators we have provided on-premise access to the servers used to generate the original nginx workload results from the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`
* please reach out to the authors if there are any further questions regarding accessing our on-premise hosts