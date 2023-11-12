### Nginx Workload Experiments
* Corresponds to figures 11 and 12 in [SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact](https://www.hpca-conf.org/2024)<br>
***HPCA 2024 Artifact Evaluators*** should skip to [Artifact Evaluation instructions](#artifact-evaluation-instructions) below

#### Setting up Cloudlab Instances:
To ease reproduction we have created a cloudlab environment and setup closely matching the server configuration used in the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`

Following the instructions below will provision a cloudlab instance in which the SPEC 2017 and (de)compression workloads
from the paper will be executed. For more information, refer to [`SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`](https://www.hpca-conf.org/2024)

* allocate a cloudlab instance using the genilib script provided in this repo
	* Create a cloudlab account if needed
	* Navigate to `Experiments`, then `Create Experiment Profile`, and upload `nginx_workload.profile`

### Compressed File Server Setup and Workload Generation
* dut setup: (e.g., run on dut from `async_nginx_build` directory)
```sh
./scripts/configure.sh
make default # build baseline nginx
cd nginx_compress_emul
./default_build.sh # gzip build
./emul_build.sh # accelerated gzip build
cd ..
make qtls # qat build -- assumes QAT c62x series PCIe adaptor installed

# setup server with files
./scripts/L5P_DRAM_Experiments/setup_server.sh 16K
./scripts/L5P_DRAM_Experiments/setup_server.sh 4K
```

* workload generation and result collection
```sh
# update vars/env.src WRK_ROOT and ROOT_DIR variables to wrk_offloadenginesupport and async_nginx_build directories, respectively
git submodule update --init .
cd client_ossls
./build_1_1_1f.sh
cd ../client_wrks
make default_wrk
cd ..

# modify vars/env.src #pollux remote config to use dut IP, async_nginx_build directory, hostname, and netdev
source vars/env.src

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
compress_var_file_sizes # max RPS Compression test

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file_compress # parse results to stdout (Normalize to accel-gzip to http-gzip for RPS comparison)

cd ..
git submodule update --init wrk2
cd wrk2
make -j
cd ..

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
compress_var_file_sizes_const # constant RPS membw and CPU Util test

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file_compress_const # output csv to stdout (Normalize to accel-gzip to http-gzip for mem-bw and cpu-util comparison)
```

### TLS-Encrypted File Server Experiments
* dut setup: (e.g., run on dut from `async_nginx_build` directory)
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

# modify vars/env.src #pollux remote config to use dut IP, async_nginx_build directory, hostname, and netdev
source vars/env.src

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
multi_many_file_var # max RPS test

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file

cd ..

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
multi_many_constrps_var_files # tls membw cpu test

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file_const
```

#### Artifact Evaluation Instructions:
To ease reproducibility for our artifact evaluators we have provided on-premise access to the servers used to generate the original nginx workload results from the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`
* please reach out to the authors if there are any further questions regarding accessing our on-premise hosts

##### Run Experiments on castor (workload generator) and pollux (dut)
* from castor:/home/shared/wrk_offloadenginesupport
```sh
source vars/env.src

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
compress_var_file_sizes # max RPS Compression test

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file_compress # parse results to stdout (Normalize to accel-gzip to http-gzip for RPS comparison)
cd ..

compress_var_file_sizes # max RPS Compression test

parse_many_multi_file_compress # parse results to stdout (Normalize to accel-gzip to http-gzip for RPS comparison)
cd ..

multi_many_file_var # max RPS test

parse_many_multi_file
cd ..

multi_many_constrps_var_files # tls membw cpu test

parse_many_multi_file_const
cd ..
```