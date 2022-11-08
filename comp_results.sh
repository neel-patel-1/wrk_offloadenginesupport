#!/bin/bash
for i in `seq 1 100`; do wget --header="accept-encoding:gzip, deflate" http://192.168.1.2/rand_file_4K.txt 2>&1 | grep -Eo '[0-9]+\.?[0-9]* [A-Z]B/s'; done | ministat
