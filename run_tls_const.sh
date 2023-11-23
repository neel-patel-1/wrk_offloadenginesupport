#!/bin/bash
source vars/env.src # set up environment variables

source ${WRK_ROOT}/utils/tests/test_funcs.sh;
multi_many_constrps_var_files # 

source ${WRK_ROOT}/utils/tests/parse_utils.sh;
parse_many_multi_file_const
cd ..
