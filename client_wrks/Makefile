# modded wrk -- openssl 3.0.0
# default wrk -- openssl 1.1.1f
# engine wrk -- openssl 1.1.1f
.PHONY: ktls_wrk default_wrk all engine_wrk clean
OPENSSLS = ../client_ossls

all: ktls_wrk default_wrk engine_wrk

ktls_wrk: autonomous-asplos21-artifact/openssl/libssl.so.3 wrk/Makefile
	(cd autonomous-asplos21-artifact/ \
		&& WITH_OPENSSL=$$(pwd)/openssl make wrk )

autonomous-asplos21-artifact/openssl/libssl.so.3: openssl/config
	(cd autonomous-asplos21-artifact/openssl &&\
		./config enable-ktls enable-ssl3 enable-threads shared linux-x86_64 && make -j)

wrk/Makefile:
	cd autonomous-asplos21-artifact && git submodule init && \
		git submodule update wrk

openssl/config:
	cd autonomous-asplos21-artifact && git submodule init && \
		git submodule update openssl

default_wrk: $(OPENSSLS)/openssl-1.1.1f/libssl.so.1.1
	(cd wrk && \
		WITH_OPENSSL=$(OPENSSLS)/openssl-1.1.1f make -j 20 )

$(OPENSSLS)/openssl-1.1.1f/libssl.so.1.1:
	cd $(OPENSSLS) && ./build_1_1_1f.sh

engine_wrk: $(OPENSSLS)/openssl-1.1.1f/libssl.so.1.1
	(cd wrk_offload_engine && \
		WITH_OPENSSL=$(OPENSSLS)/openssl-1.1.1f make -j 20 )

clean:
	make -C wrk_offload_engine clean
	make -C wrk clean
	make -C autonomous-asplos21-artifact clean
