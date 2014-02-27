#ifndef __METISCOIN_MINER_H__
#define __METISCOIN_MINER_H__
#include "global.h"

// utils
int log2(size_t value);


class MetiscoinOpenCL {
public:
	MetiscoinOpenCL(int _device_num, uint32_t _step_size);
	virtual ~MetiscoinOpenCL() { };
	virtual void metiscoin_process(minerMetiscoinBlock_t* block) = 0;
protected:
	int device_num;
	uint32_t STEP_SIZE;
	uint32_t NUM_STEPS;

	OpenCLBuffer* u;
	OpenCLBuffer* buff;
	OpenCLBuffer* hashes;
	OpenCLBuffer* out;
	OpenCLBuffer* out_count;
	OpenCLBuffer* begin_nonce;
	OpenCLBuffer* target;
	OpenCLCommandQueue * q;
	cl_uint out_tmp[255];
	cl_uint tmp_out_count;
	cl_uint tmp_begin_nonce;
	cl_uint tmp_target;

	size_t wg_size;
};


class MetiscoinOpenCLConstant : public MetiscoinOpenCL {
public:

	MetiscoinOpenCLConstant(int device_num, uint32_t _step_size);
	void metiscoin_process(minerMetiscoinBlock_t* block);
private:
	OpenCLKernel* kernel_all;
	OpenCLKernel* kernel_keccak_noinit;
	OpenCLKernel* kernel_shavite;
	OpenCLKernel* kernel_metis;
};

class MetiscoinOpenCLGlobal : public MetiscoinOpenCL {
public:

	MetiscoinOpenCLGlobal(int _device_num, uint32_t _step_size);
	void metiscoin_process(minerMetiscoinBlock_t* block);
private:

	OpenCLKernel* kernel_all;
	OpenCLKernel* kernel_keccak_noinit;
	OpenCLKernel* kernel_shavite;
	OpenCLKernel* kernel_metis;

	OpenCLBuffer* shavite_lookup;
	OpenCLBuffer* fugue_lookup;
};

#endif
