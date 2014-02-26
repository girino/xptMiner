#ifndef __METISCOIN_MINER_H__
#define __METISCOIN_MINER_H__
#include "global.h"

// utils
int log2(size_t value);


class MetiscoinOpenCL {
public:
	MetiscoinOpenCL() { };
	virtual ~MetiscoinOpenCL() { };
	virtual void metiscoin_process(minerMetiscoinBlock_t* block) = 0;
};


class MetiscoinOpenCLConstant : public MetiscoinOpenCL {
public:

	MetiscoinOpenCLConstant(int device_num, uint32_t _step_size);
	void metiscoin_process(minerMetiscoinBlock_t* block);
private:

	int device_num;
	uint32_t STEP_SIZE;
	uint32_t NUM_STEPS;

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

class MetiscoinOpenCLGlobal : public MetiscoinOpenCL {
public:

	MetiscoinOpenCLGlobal(int device_num);
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
