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
```
cd client_wrks
make ktls_wrk
```


```
/home/n869p538/wrk_offloadenginesupport/client_wrks/wrk_offload_engine/wrk: invalid option -- 'R'
[3]   Exit 1                  ${1}_mt_core $2 $3 $4 $5 $( getport $1 ) ${7} $9 > $8
```
* compile client_wrk (wrk_offloadenginesupport)
```
cd wrk2_offload_engine/
make -j
```

dut issues:
```
(base) n869p538@pollux:async_nginx_build$ ./scripts/L5P_DRAM_Experiments/setup_server.sh 4K
mount: /home/shared/wrk_offloadenginesupport/async_nginx_build/axdimm/nginx_build/html: mount point does not exist.
mount: /home/shared/wrk_offloadenginesupport/async_nginx_build/ktls/nginx_build/html: mount point does not exist.
mount: /home/shared/wrk_offloadenginesupport/async_nginx_build/qtls/async_mode_nginx_build/html: mount point does not exist.
mount: /home/shared/wrk_offloadenginesupport/async_nginx_build/qtls/async_mode_nginx_build/html: mount point does not exist.
```
* compile all nginx servers:
```
make axdimm
make qtls
make ktls
```