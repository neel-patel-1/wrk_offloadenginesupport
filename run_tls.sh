#!/bin/bash
source vars/env.src # set up environment variables

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
multi_many_file_var # max RPS test

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file
cd ..
