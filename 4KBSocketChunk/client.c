/*
 * =====================================================================================
 *
 *       Filename:  client.c
 *
 *    Description:  
 *
 *        Version:  1.0
 *        Created:  2013年08月19日 17时19分33秒
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (), 
 *   Organization:  
 *
 * =====================================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <error.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <time.h>

#define SEVPORT 3333
#define MAXDATASIZE  (1024*16)
#define ITER 100

#define TIME_DIFF(t1,t2) (((t1).tv_sec-(t2).tv_sec)*1000+((t1).tv_usec-(t2).tv_usec)/1000)

main(int argc, char *argv[])
{
	int sockfd,sendbytes,recvbytes;
	char buf[MAXDATASIZE];
	struct hostent *host;
	struct sockaddr_in serv_addr;
	struct timeval timestamp;
	struct timeval timestamp_end;
	int do_16=0;
	if(argc < 2){
		fprintf(stderr,"Please enter the server's hostname!\n");
		exit(1);
	}
	if(argc < 3){
		fprintf(stderr,"Please enter the size\n");
		exit(1);
	}
	do_16=atoi(argv[2]);

	if((host=gethostbyname(argv[1])) == NULL){
		perror("gethostbyname:");
		exit(1);
	}
#ifdef CLIENT_DEBUG
	printf("hostent h_name: %s , h_aliases: %s,\
			h_addrtype: %d, h_length: %d, h_addr_list: %s\n",\
			host->h_name,*(host->h_aliases),host->h_addrtype,host->h_length,*(host->h_addr_list));
#endif

	if((sockfd = socket(AF_INET,SOCK_STREAM,0)) == -1){
		perror("socket:");
		exit(1);
	}

	serv_addr.sin_family = AF_INET;
	serv_addr.sin_port = htons(SEVPORT);
	serv_addr.sin_addr = *((struct in_addr *)host->h_addr);
	bzero(&(serv_addr.sin_zero),8);

	if(connect(sockfd,(struct sockaddr *)&serv_addr, \
					sizeof(struct sockaddr)) == -1){
		perror("connect:");
		exit(1);
	}
	memset(buf,0x15, sizeof(buf));
	gettimeofday(&timestamp,NULL);
		
	int i=0;
	clock_t st = clock();
	if (do_16 != 1) { 
		for ( int i=0; i<4; i++ ){
			if((sendbytes = write(sockfd,buf+(4096*i),4096)) == -1){
				perror("send:");
				exit(1);
			}
		}
	}
	else{
		if((sendbytes = write(sockfd,buf,16*1024)) == -1){
			perror("send:");
			exit(1);
		}
	}
	clock_t diff = clock() - st;

	if (do_16 != 1) { 
		printf("4KB_NS:%ld\n", (diff * 1000000) /CLOCKS_PER_SEC);
	}
	else{
		printf("16KB_NS:%ld\n", (diff * 1000000) /CLOCKS_PER_SEC);
	}

	close(sockfd);
}
