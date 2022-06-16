#!/usr/bin/env bpftrace
BEGIN
{
	printf("TX time: (KernelCpy - UserAxCpy)\n");
}

uretprobe:/home/n869p538/wrk_offloadenginesupport/async_nginx_build/axdimm/openssl/lib/engines-1.1/qatengine.so:aes_gcm_tls_cipher /comm=="nginx"/
{ 
	@cpy_start[pid]=nsecs; 
} 

kprobe:tcp_sendmsg_locked /@cpy_start[pid]/ 
{  
	@copy_delay_hist=hist(nsecs - @cpy_start[pid]); 
	@copy_delay_avg=avg(nsecs - @cpy_start[pid]);
}
