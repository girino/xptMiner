#ifndef __METISCOIN_MINER_H__
#define __METISCOIN_MINER_H__
#include "global.h"


class MetiscoinOpenCL {
public:

	MetiscoinOpenCL(int device_num);
	void metiscoin_process(minerMetiscoinBlock_t* block);
private:

	int device_num;

	OpenCLKernel* kernel_all;
	OpenCLKernel* kernel_keccak_noinit;
	OpenCLKernel* kernel_shavite;
	OpenCLKernel* kernel_metis;
	OpenCLBuffer* u;
	OpenCLBuffer* buff;
	OpenCLBuffer* hashes;
	OpenCLBuffer* out;
	OpenCLBuffer* out_count;
	OpenCLCommandQueue * q;
	cl_uint out_tmp[255];
};

#endif
