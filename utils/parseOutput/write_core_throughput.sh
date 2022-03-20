#!/bin/bash
sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1 \2/p' <&0
#sed -E -n -e 's/Transfer\/sec:\s*([0-9]*.[0-9]*)(MB|GB|B|KB)/\1 \2/p' -e 's/Latency\s+[0-9a-z.]*\s+[0-9a-z.]*\s+([0-9a-z.]*)\s+([0-9a-z.]*%)/\1 \2 /p'
