## SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact
This repository contains scripts for SmartDIMM HPCA'24 artifact evaluation of the 
**SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact** paper by 
Neel Patel, Amin Mamandipoor, and Mohammad Alian

### Evaluation instructions ###
* start by executing `git submodule update --init --recursive` to fetch all submodules and dependencies

The scripts in this paper can be used to reproduce:
* Figure 10: SmartDIMM Scratchpad Utilization
* Figure 11: Encrypted Nginx Performance (Nginx Server for Encrypted Files) Measures RPS, CPU Utilization,
and Memory Bandwidth for a server producing TLS-encrypted HTTP responses driven by the wrk workload 
generator
* Figure 12: Compressed Nginx Performance (Nginx Server for Compressed Files) Measures RPS, CPU Utilization,
and Memory Bandwidth for a server producing gzip-compressed HTTP responses driven by the wrk workload 
generator

### Directory Structure
```
|--- Near-Memory-Sensitivity-Analysis: SmartDIMM sensitivity analysis examining the resource utilization for different server loads
|--- wrk_offloadenginesupport: workload generation scripts based on the `wrk` http request generation tool
  |--- async_nginx_build: nginx server configuration files and builds for baseline http, https, and accelerated https using QAT and kTLS
```

### Nginx Workload Experiments
* Corresponds to figures 11 and 12 in [SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact](https://www.hpca-conf.org/2024)<br>

#### Artifact Evaluation Instructions:
To ease reproducibility for our artifact evaluators we have created a cloudlab environment and setup closely matching the server configuration used in the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`

#### Setting up Cloudlab Instances:
To ease reproducibility for our artifact evaluators we have created a cloudlab environment and setup closely matching the server configuration used in the HPCA 2024 paper `SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`

Following the instructions below will provision a cloudlab instance in which the SPEC 2017 and (de)compression workloads
from the paper will be executed. For more information, refer to [`SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`](https://www.HPCA 56.org/)

* allocate a cloudlab instance using the genilib script provided in this repo
	* Create a cloudlab account if needed
	* Navigate to `Experiments`, then `Create Experiment Profile`, and upload `nginx_workload.profile`

### Generating Results
* Change SPEC\_ROOT in `shared.sh` to the root directory of a SPEC 2017 installation
	* Follow instructions here to build spec: [SPEC\_2017 Quick Start Guide](https://www.spec.org/cpu2017/Docs/quick-start.html)
	* For HPCA 2024 Artifact Evaluators we have provided a genilib script and instructions for regenerating results on a cloudlab instance:


#### Artifact Evaluation Instructions:


* we have provided a SPEC 2017 Image which can be used during the duration of the Artifact Evaluation process only for reproducing the results in [`SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`](https://www.HPCA 56.org/). 
* An official SPEC 2017 benchmark set for the duration of the evaluation process can be fetched via `wget https://ae_private_resources.amazonaws.com/cpu2017-1_0_5.iso`
* Next prepare SPEC 2017 for workload evaluation:

```sh
mkdir spec_mnt
mkdir spec
sudo mount -t iso9660 -o ro,exec,loop /path/to/cpu2017-1_0_5.iso ./spec_mnt
cd spec_mnt
./install.sh -d ../spec 

# respond with yes when prompted

# change SPEC_ROOT to /path/to/spec in shared.sh

# change config/default.cfg gcc_dir to /usr

cp config/default.cfg  /path/to/spec/config/
```

* install dependencies
```sh
sudo apt update
sudo apt install gfortran
```

* Build Compression/Decompression Antagonist thread workload and fetch sample files
```sh
./fetch_corpus.sh
cd lzbench
make -j BUILD_STATIC=1
```

* run jobmix1 configuration with and without (de)compression antagonists
```sh
cd $spec_workload_experiment_root
./run.sh # run both spec jobmix1 configurations and print job degradation between antagonist and baseline configurations
```

* Note: As SPEC 2017 is a licensed software, we ask reviewers only utilize the provided SPEC 2017 distribution (e.g., in the form of a disk image `cpu2017-1_0_5.iso`) for the use of reproducing the results presented in [`SmartDIMM:  In-Memory Acceleration of Upper Layer I/O Protocols Artifact`](https://www.HPCA 56.org/).
	* License: https://www.spec.org/cpu2017/Docs/licenses/SPEC-License.pdf

#### Testing other corunning workloads and configurations
* Change SPEC\_CORES and BENCHS in `shared.sh` to the cores and workloads to corun with the (De)compression threads
* Change COMP\_CORES to a non-overlapping set of cores on which to run the (de)compressor threads

#### Parsing Results
* execute `./parse.sh` to view the runtimes of the executed SPEC workloads generated during the previous step
