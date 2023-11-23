#!/bin/bash
source vars/env.src

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
compress_var_file_sizes # max RPS Compression test

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file_compress # parse results to stdout (Normalize to accel-gzip to http-gzip for RPS comparison)
cd ..
