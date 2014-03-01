#ifndef __INCLUDE_GLOBAL_H__
#define __INCLUDE_GLOBAL_H__

#if defined(__WIN32__) && !defined(__CYGWIN__)
#pragma comment(lib,"Ws2_32.lib")
#include<Winsock2.h>
#include<ws2tcpip.h>
#elif defined(__CYGWIN__)
#include"win.h" // port from windows
#else
#include"win.h" // port from windows
#endif

#define mymax(a, b) \
    ((a)>(b)?(a):(b))

#define mymin(a, b) \
    ((a)<(b)?(a):(b))

#include<stdio.h>
#include<time.h>
#include<stdlib.h>

#include"jhlib.h" // slim version of jh library

// connection info for xpt
typedef struct  
{
	char* ip;
	uint16 port;
	char* authUser;
	char* authPass;
	float donationPercent;
}generalRequestTarget_t;

#include"xptServer.h"
#include"xptClient.h"

#include"sha2.h"
#include"sph_keccak.h"
#include"sph_metis.h"
#include"sph_shavite.h"

#include"transaction.h"

enum GPUALGO { CONSTANT_MEMSPACE = 1, GLOBAL_MEMSPACE, SINGLE };

// global settings for miner
typedef struct  
{
	generalRequestTarget_t requestTarget;
}minerSettings_t;

extern minerSettings_t minerSettings;

// block data struct

typedef struct  
{
	// block data (order and memory layout is important)
	uint32	version;
	uint8	prevBlockHash[32];
	uint8	merkleRoot[32];
	uint32	nTime;
	uint32	nBits;
	uint32	nonce;
	// remaining data
	uint32	uniqueMerkleSeed;
	uint32	height;
	uint8	merkleRootOriginal[32]; // used to identify work
	uint8	target[32];
	uint8	targetShare[32];
}minerMetiscoinBlock_t; // identical to scryptBlock

void xptMiner_submitShare(minerMetiscoinBlock_t* block);

// stats
extern volatile uint32 totalShareCount;
extern volatile uint32 totalRejectedShareCount;
extern volatile uint64 totalCollisionCount;
extern volatile uint32 invalidShareCount;


extern volatile uint32 monitorCurrentBlockHeight;
extern volatile uint32 monitorCurrentBlockTime;

#endif
