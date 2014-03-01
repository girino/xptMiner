#include"global.h"
#include "OpenCLObjects.h"
#include "ticker.h"
#include "metiscoinMiner.h"
#include "tables_single.h"

//#define STEP_SIZE 0x10000
//#define NUM_STEPS 0x1000
//#define STEP_MULTIPLIER 0x10000

int log2(size_t value) {
	int ret = 0;
	while (value > 1) {
		ret++;
		value = value>>1;
	}
	return ret;
}

MetiscoinOpenCL::MetiscoinOpenCL(int _device_num, uint32_t _step_size) {
	this->device_num = _device_num;
	this->STEP_SIZE = _step_size;
	this->NUM_STEPS = (uint32)(0x10000000L/STEP_SIZE);
	printf("Initializing GPU %d\n", device_num);
	OpenCLMain &main = OpenCLMain::getInstance();
	OpenCLDevice* device = main.getDevice(device_num);
	printf("Initializing Device: %s\n", device->getName().c_str());

	q = device->getContext()->createCommandQueue(device);

	u = device->getContext()->createBuffer(25*sizeof(cl_ulong), CL_MEM_READ_ONLY, NULL);
	buff = device->getContext()->createBuffer(4, CL_MEM_READ_ONLY, NULL);

	hashes = device->getContext()->createBuffer(64 * STEP_SIZE, CL_MEM_READ_WRITE, NULL);
	out = device->getContext()->createBuffer(sizeof(cl_uint) * 255, CL_MEM_WRITE_ONLY, NULL);
	out_count = device->getContext()->createBuffer(sizeof(cl_uint), CL_MEM_READ_WRITE, NULL);
	begin_nonce = device->getContext()->createBuffer(sizeof(cl_uint), CL_MEM_READ_ONLY, NULL);
	target = device->getContext()->createBuffer(sizeof(cl_uint), CL_MEM_READ_ONLY, NULL);
}


MetiscoinOpenCLConstant::MetiscoinOpenCLConstant(int _device_num, uint32_t _step_size) : MetiscoinOpenCL(_device_num, _step_size) {

	printf ("Initing algo with constant memspace...\n");

	OpenCLMain &main = OpenCLMain::getInstance();
	OpenCLDevice* device = main.getDevice(device_num);
	std::vector<std::string> files_keccak;
	files_keccak.push_back("opencl/common.cl");
	files_keccak.push_back("opencl/keccak.cl");
	files_keccak.push_back("opencl/shavite_NVidia.cl"); // way faster on NVidia, not much slower on AMD
	//files_keccak.push_back("opencl/shavite_AMD.cl");
	files_keccak.push_back("opencl/metis.cl");
	files_keccak.push_back("opencl/tables.cl");
	files_keccak.push_back("opencl/miner_constant.cl");
#ifdef VALIDATE_ALGORITHMS
	OpenCLProgram* program = device->getContext()->loadProgramFromFiles(files_keccak, "-DVALIDATE_ALGORITHMS");
#else
	OpenCLProgram* program = device->getContext()->loadProgramFromFiles(files_keccak);
#endif
	kernel_keccak_noinit = program->getKernel("keccak_step_noinit");
	kernel_shavite = program->getKernel("shavite_step");
	kernel_metis = program->getKernel("metis_step");

	// params
	//kernel void keccak_step_noinit(constant const ulong* u, constant const char* buff, global ulong* out, uint begin_nonce)
	kernel_keccak_noinit->resetArgs();
	kernel_keccak_noinit->addGlobalArg(u);
	kernel_keccak_noinit->addGlobalArg(buff);
	kernel_keccak_noinit->addGlobalArg(hashes);
	kernel_keccak_noinit->addGlobalArg(begin_nonce);

	// shavite
	kernel_shavite->resetArgs();
	kernel_shavite->addGlobalArg(hashes);

	// metis_step(global ulong* in, global uint* out, global uint* outcount, uint begin_nonce, uint target) {
	kernel_metis->resetArgs();
	kernel_metis->addGlobalArg(hashes);
	kernel_metis->addGlobalArg(out);
	kernel_metis->addGlobalArg(out_count);
	kernel_metis->addGlobalArg(begin_nonce);
	kernel_metis->addGlobalArg(target);

	// work group sizes
	wg_size = kernel_keccak_noinit->getWorkGroupSize(device);
	size_t wgs_tmp = kernel_shavite->getWorkGroupSize(device);
	if (wgs_tmp < wg_size) wg_size = wgs_tmp;
	wgs_tmp = kernel_metis->getWorkGroupSize(device);
	if (wgs_tmp < wg_size) wg_size = wgs_tmp;
#ifdef DEBUG_WORKGROUP_SIZE
	printf ("wg_size = %d => %d\n", wg_size, 1 << log2(wg_size));
#endif
	wg_size = 1 << log2(wg_size); // guarantees to be a power of 2

}

void MetiscoinOpenCLConstant::metiscoin_process(minerMetiscoinBlock_t* block)
{

	block->nonce = 0;
	tmp_target = *(uint32*)(block->targetShare+28);
	OpenCLDevice* device = OpenCLMain::getInstance().getDevice(device_num);
	//printf("processing block with Device: %s\n", device->getName().c_str());

	sph_keccak512_context	 ctx_keccak;
	sph_keccak512_init(&ctx_keccak);
	sph_keccak512(&ctx_keccak, &block->version, 80);

	q->enqueueWriteBuffer(u, ctx_keccak.u.narrow, 25*sizeof(cl_ulong));
	q->enqueueWriteBuffer(buff, ctx_keccak.buf, 4);
	q->enqueueWriteBuffer(target, &tmp_target, sizeof(cl_uint));

	// measure time
	for (uint32 n = 0; n < NUM_STEPS; n++)
	{
#ifdef MEASURE_TIME
		uint32 begin = getTimeMilliseconds();
#endif
		if( block->height != monitorCurrentBlockHeight )
			break;
		//keccak
		tmp_begin_nonce = n * STEP_SIZE;
		q->enqueueWriteBuffer(begin_nonce, &tmp_begin_nonce, sizeof(cl_uint));

		q->enqueueKernel1D(kernel_keccak_noinit, STEP_SIZE,
				wg_size);

#ifdef MEASURE_TIME
		printf("keccak work group size = %d\n", kernel_keccak_noinit->getWorkGroupSize(device));
		q->finish();
		uint32 end_keccak = getTimeMilliseconds();
#endif

		// shavite
		q->enqueueKernel1D(kernel_shavite, STEP_SIZE, wg_size);

#ifdef MEASURE_TIME
		printf("shavite work group size = %d\n", kernel_shavite->getWorkGroupSize(device));
		q->finish();
		uint32 end_shavite = getTimeMilliseconds();
#endif
		// metis
		tmp_out_count = 0;
		q->enqueueWriteBuffer(out_count, &tmp_out_count, sizeof(cl_uint));
		q->enqueueKernel1D(kernel_metis, STEP_SIZE, wg_size);
		q->enqueueReadBuffer(out, out_tmp, sizeof(cl_uint) * 255);
		q->enqueueReadBuffer(out_count, &tmp_out_count, sizeof(cl_uint));
		q->finish();

		for (int i = 0; i < tmp_out_count; i++) {
			totalShareCount++;
			block->nonce = out_tmp[i];
			xptMiner_submitShare(block);
		}

		totalCollisionCount += STEP_SIZE;
#ifdef MEASURE_TIME
		uint32 end = getTimeMilliseconds();
		printf("Elapsed time: %d (k = %d, s = %d, m = %d) ms\n", (end-begin), (end_keccak-begin), (end_shavite-end_keccak), (end-end_shavite));
#endif

#ifdef VALIDATE_ALGORITHMS
		uint32 begin_validation = getTimeMilliseconds();

		cl_ulong *tmp_hashes = new cl_ulong[8 * STEP_SIZE];
		q->enqueueReadBuffer(hashes, tmp_hashes,
				sizeof(cl_ulong) * 8 * STEP_SIZE);
		q->finish();

		int aaa = 0;
		for (int i = 0; i < STEP_SIZE; i++) {
			cl_ulong * hhh = tmp_hashes+(i*8);
			if( *(cl_uint*)((cl_uchar*)hhh+28) <= tmp_target )
			{
				aaa++;
			}
		}

		if (aaa != tmp_out_count) {
			printf ("************* ERRO ****************\n");
			exit(0);
		}


		// validator
		block->nonce = (n*STEP_SIZE);
		for (int f2 = 0; f2 < STEP_SIZE; f2++) {
			sph_keccak512_context	 ctx_keccak;
			sph_shavite512_context	 ctx_shavite;
			sph_metis512_context	 ctx_metis;
			cl_ulong hash0[8];
			cl_ulong hash1[8];
			cl_ulong hash2[8];
			cl_ulong *hash1_2;
			cl_ulong *hash2_2;

			sph_keccak512_init(&ctx_keccak);
			sph_shavite512_init(&ctx_shavite);
			sph_metis512_init(&ctx_metis);
			sph_keccak512(&ctx_keccak, &block->version, 80);
			sph_keccak512_close(&ctx_keccak, hash0);
			sph_shavite512(&ctx_shavite, hash0, 64);
			sph_shavite512_close(&ctx_shavite, hash1);
			sph_metis512(&ctx_metis, hash1, 64);
			sph_metis512_close(&ctx_metis, hash2);

			hash2_2 = tmp_hashes+(f2*8);

			for (int i = 0; i < 8; i++) {
				if (hash2[i] != hash2_2[i]) {
					printf ("**** Hashes do not match %d/%d %x %x\n", f2, i, hash0[i], hash2_2[i]);
				}
			}

//			for (int i = 0; i < 8; i++) {
//				if (hash0[i] != hash2_2[i]) {
//					printf ("**** Hashes do not match %d/%d %lx %lx\n", f, i, hash0[i], hash2_2[i]);
//
//				}
//				if (ctx_keccak.buf[i] = hash2_2[i]) {
//					printf ("**** Hashes do not match %d/%d %x %x\n", f, i, ctx_keccak.buf[i], hash2_2[i]);
//				}
//			}
//			if (f == 32) exit(0);

			block->nonce++;
		}
		delete tmp_hashes;
		block->nonce = 0;
		uint32 end_validation = getTimeMilliseconds();
		printf("Validation time: %d ms\n", (end_validation-begin_validation));
#endif
	}

}

MetiscoinOpenCLGlobal::MetiscoinOpenCLGlobal(int _device_num, uint32_t _step_size) : MetiscoinOpenCL(_device_num, _step_size) {

	printf ("Initing algo with global memspace...\n");

	OpenCLMain &main = OpenCLMain::getInstance();
	OpenCLDevice* device = main.getDevice(device_num);
	std::vector<std::string> files_keccak;
	files_keccak.push_back("opencl/common.cl");
	files_keccak.push_back("opencl/keccak.cl");
	files_keccak.push_back("opencl/shavite_NVidia.cl"); // way faster on NVidia, not much slower on AMD
	//files_keccak.push_back("opencl/shavite_AMD.cl");
	files_keccak.push_back("opencl/metis.cl");
	files_keccak.push_back("opencl/miner_global.cl");
#ifdef VALIDATE_ALGORITHMS
	OpenCLProgram* program = device->getContext()->loadProgramFromFiles(files_keccak, "-DVALIDATE_ALGORITHMS");
#else
	OpenCLProgram* program = device->getContext()->loadProgramFromFiles(files_keccak);
#endif
	kernel_keccak_noinit = program->getKernel("keccak_step_noinit");
	kernel_shavite = program->getKernel("shavite_step");
	kernel_metis = program->getKernel("metis_step");

	// allocs lookup tables
	fugue_lookup = device->getContext()->createBuffer(1024*sizeof(cl_uint), CL_MEM_READ_ONLY, NULL);
	shavite_lookup = device->getContext()->createBuffer(1024*sizeof(cl_uint), CL_MEM_READ_ONLY, NULL);
	// enqueue write tables
	q->enqueueWriteBuffer(shavite_lookup, (void*)AES_c, 1024*sizeof(cl_uint));
	q->enqueueWriteBuffer(fugue_lookup, (void*)mixtab_c, 1024*sizeof(cl_uint));

	// params
	//kernel void keccak_step_noinit(constant const ulong* u, constant const char* buff, global ulong* out, uint begin_nonce)
	kernel_keccak_noinit->resetArgs();
	kernel_keccak_noinit->addGlobalArg(u);
	kernel_keccak_noinit->addGlobalArg(buff);
	kernel_keccak_noinit->addGlobalArg(hashes);
	kernel_keccak_noinit->addGlobalArg(begin_nonce);

	// shavite
	kernel_shavite->resetArgs();
	kernel_shavite->addGlobalArg(hashes);
	kernel_shavite->addGlobalArg(shavite_lookup);

	// metis_step(global ulong* in, global uint* out, global uint* outcount, uint begin_nonce, uint target) {
	kernel_metis->resetArgs();
	kernel_metis->addGlobalArg(hashes);
	kernel_metis->addGlobalArg(out);
	kernel_metis->addGlobalArg(out_count);
	kernel_metis->addGlobalArg(begin_nonce);
	kernel_metis->addGlobalArg(target);
	kernel_metis->addGlobalArg(fugue_lookup);

	// work group sizes
	wg_size = kernel_keccak_noinit->getWorkGroupSize(device);
	size_t wgs_tmp = kernel_shavite->getWorkGroupSize(device);
	if (wgs_tmp < wg_size) wg_size = wgs_tmp;
	wgs_tmp = kernel_metis->getWorkGroupSize(device);
	if (wgs_tmp < wg_size) wg_size = wgs_tmp;
#ifdef DEBUG_WORKGROUP_SIZE
	printf ("wg_size = %d => %d\n", wg_size, 1 << log2(wg_size));
#endif
	wg_size = 1 << log2(wg_size); // guarantees to be a power of 2

}

void MetiscoinOpenCLGlobal::metiscoin_process(minerMetiscoinBlock_t* block)
{

	block->nonce = 0;
	tmp_target = *(uint32*)(block->targetShare+28);
	OpenCLDevice* device = OpenCLMain::getInstance().getDevice(device_num);
	//printf("processing block with Device: %s\n", device->getName().c_str());

	sph_keccak512_context	 ctx_keccak;
	sph_keccak512_init(&ctx_keccak);
	sph_keccak512(&ctx_keccak, &block->version, 80);

	q->enqueueWriteBuffer(u, ctx_keccak.u.narrow, 25*sizeof(cl_ulong));
	q->enqueueWriteBuffer(buff, ctx_keccak.buf, 4);
	q->enqueueWriteBuffer(target, &tmp_target, sizeof(cl_uint));

	// measure time
	for (uint32 n = 0; n < NUM_STEPS; n++)
	{
#ifdef MEASURE_TIME
		uint32 begin = getTimeMilliseconds();
#endif
		if( block->height != monitorCurrentBlockHeight )
			break;
		//keccak
		tmp_begin_nonce = n * STEP_SIZE;
		q->enqueueWriteBuffer(begin_nonce, &tmp_begin_nonce, sizeof(cl_uint));

		q->enqueueKernel1D(kernel_keccak_noinit, STEP_SIZE,
				wg_size);

#ifdef MEASURE_TIME
		printf("keccak work group size = %d\n", kernel_keccak_noinit->getWorkGroupSize(device));
		q->finish();
		uint32 end_keccak = getTimeMilliseconds();
#endif

		// shavite
		q->enqueueKernel1D(kernel_shavite, STEP_SIZE, wg_size);

#ifdef MEASURE_TIME
		printf("shavite work group size = %d\n", kernel_shavite->getWorkGroupSize(device));
		q->finish();
		uint32 end_shavite = getTimeMilliseconds();
#endif
		// metis
		tmp_out_count = 0;
		q->enqueueWriteBuffer(out_count, &tmp_out_count, sizeof(cl_uint));
		q->enqueueKernel1D(kernel_metis, STEP_SIZE, wg_size);
		q->enqueueReadBuffer(out, out_tmp, sizeof(cl_uint) * 255);
		q->enqueueReadBuffer(out_count, &tmp_out_count, sizeof(cl_uint));
		q->finish();

		for (int i = 0; i < tmp_out_count; i++) {
			totalShareCount++;
			block->nonce = out_tmp[i];
			xptMiner_submitShare(block);
		}

		totalCollisionCount += STEP_SIZE;
#ifdef MEASURE_TIME
		uint32 end = getTimeMilliseconds();
		printf("Elapsed time: %d (k = %d, s = %d, m = %d) ms\n", (end-begin), (end_keccak-begin), (end_shavite-end_keccak), (end-end_shavite));
#endif

#ifdef VALIDATE_ALGORITHMS
		uint32 begin_validation = getTimeMilliseconds();

		cl_ulong *tmp_hashes = new cl_ulong[8 * STEP_SIZE];
		q->enqueueReadBuffer(hashes, tmp_hashes,
				sizeof(cl_ulong) * 8 * STEP_SIZE);
		q->finish();

		int aaa = 0;
		for (int i = 0; i < STEP_SIZE; i++) {
			cl_ulong * hhh = tmp_hashes+(i*8);
			if( *(cl_uint*)((cl_uchar*)hhh+28) <= tmp_target )
			{
				aaa++;
			}
		}

		if (aaa != tmp_out_count) {
			printf ("************* ERRO ****************\n");
			exit(0);
		}


		// validator
		block->nonce = (n*STEP_SIZE);
		for (int f2 = 0; f2 < STEP_SIZE; f2++) {
			sph_keccak512_context	 ctx_keccak;
			sph_shavite512_context	 ctx_shavite;
			sph_metis512_context	 ctx_metis;
			cl_ulong hash0[8];
			cl_ulong hash1[8];
			cl_ulong hash2[8];
			cl_ulong *hash1_2;
			cl_ulong *hash2_2;

			sph_keccak512_init(&ctx_keccak);
			sph_shavite512_init(&ctx_shavite);
			sph_metis512_init(&ctx_metis);
			sph_keccak512(&ctx_keccak, &block->version, 80);
			sph_keccak512_close(&ctx_keccak, hash0);
			sph_shavite512(&ctx_shavite, hash0, 64);
			sph_shavite512_close(&ctx_shavite, hash1);
			sph_metis512(&ctx_metis, hash1, 64);
			sph_metis512_close(&ctx_metis, hash2);

			hash2_2 = tmp_hashes+(f2*8);

			for (int i = 0; i < 8; i++) {
				if (hash2[i] != hash2_2[i]) {
					printf ("**** Hashes do not match %d/%d %x %x\n", f2, i, hash0[i], hash2_2[i]);
				}
			}

//			for (int i = 0; i < 8; i++) {
//				if (hash0[i] != hash2_2[i]) {
//					printf ("**** Hashes do not match %d/%d %lx %lx\n", f, i, hash0[i], hash2_2[i]);
//
//				}
//				if (ctx_keccak.buf[i] = hash2_2[i]) {
//					printf ("**** Hashes do not match %d/%d %x %x\n", f, i, ctx_keccak.buf[i], hash2_2[i]);
//				}
//			}
//			if (f == 32) exit(0);

			block->nonce++;
		}
		delete tmp_hashes;
		block->nonce = 0;
		uint32 end_validation = getTimeMilliseconds();
		printf("Validation time: %d ms\n", (end_validation-begin_validation));
#endif
	}

}



MetiscoinOpenCLSingle::MetiscoinOpenCLSingle(int _device_num, uint32_t _step_size) : MetiscoinOpenCL(_device_num, _step_size) {

	printf ("Initing algo with global memspace and single kernel using local memory...\n");

	OpenCLMain &main = OpenCLMain::getInstance();
	OpenCLDevice* device = main.getDevice(device_num);
	std::vector<std::string> files_keccak;
	files_keccak.push_back("opencl/common.cl");
	files_keccak.push_back("opencl/keccak.cl");
	files_keccak.push_back("opencl/shavite_NVidia.cl"); // way faster on NVidia, not much slower on AMD
	//files_keccak.push_back("opencl/shavite_AMD.cl");
	files_keccak.push_back("opencl/metis.cl");
	files_keccak.push_back("opencl/miner_single.cl");
#ifdef VALIDATE_ALGORITHMS
	OpenCLProgram* program = device->getContext()->loadProgramFromFiles(files_keccak, "-DLOCAL_HASHES -DVALIDATE_ALGORITHMS");
#else
	OpenCLProgram* program = device->getContext()->loadProgramFromFiles(files_keccak, "-DLOCAL_HASHES");
#endif
	kernel_single_noinit = program->getKernel("single_noinit");

	// allocs lookup tables
	fugue_lookup = device->getContext()->createBuffer(1024*sizeof(cl_uint), CL_MEM_READ_ONLY, NULL);
	shavite_lookup = device->getContext()->createBuffer(1024*sizeof(cl_uint), CL_MEM_READ_ONLY, NULL);
	// enqueue write tables
	q->enqueueWriteBuffer(shavite_lookup, (void*)AES_c, 1024*sizeof(cl_uint));
	q->enqueueWriteBuffer(fugue_lookup, (void*)mixtab_c, 1024*sizeof(cl_uint));


	// work group sizes
	wg_size = kernel_single_noinit->getWorkGroupSize(device);
	// checks if there's enough local mem for the kernel
	size_t max_mem = device->getMaxMemAllocSize();
	size_t local_mem = device->getLocalMemSize();
	size_t reserved_mem = 8 * 256 * sizeof(cl_uint);
	if ((max_mem-reserved_mem)/(8*sizeof(cl_ulong)) < wg_size) wg_size = (max_mem-reserved_mem)/(8*sizeof(cl_ulong));
	if ((local_mem-reserved_mem)/(8*sizeof(cl_ulong)) < wg_size) wg_size = (local_mem-reserved_mem)/(8*sizeof(cl_ulong));
#ifdef DEBUG_WORKGROUP_SIZE
	printf ("wg_size = %d => %d\n", wg_size, 1 << log2(wg_size));
#endif
	if (STEP_SIZE % wg_size != 0) wg_size = 1 << log2(wg_size); // guarantees to be a multiple

	// params
	//kernel void keccak_step_noinit(constant const ulong* u, constant const char* buff, global ulong* out, uint begin_nonce)
	kernel_single_noinit->resetArgs();
	kernel_single_noinit->addGlobalArg(u);
	kernel_single_noinit->addGlobalArg(buff);
	kernel_single_noinit->addLocalArg(8*wg_size*sizeof(cl_ulong));
	kernel_single_noinit->addGlobalArg(shavite_lookup);
	kernel_single_noinit->addGlobalArg(fugue_lookup);
	kernel_single_noinit->addGlobalArg(out);
	kernel_single_noinit->addGlobalArg(out_count);
	kernel_single_noinit->addGlobalArg(begin_nonce);
	kernel_single_noinit->addGlobalArg(target);

}

void MetiscoinOpenCLSingle::metiscoin_process(minerMetiscoinBlock_t* block)
{

	block->nonce = 0;
	tmp_target = *(uint32*)(block->targetShare+28);
	OpenCLDevice* device = OpenCLMain::getInstance().getDevice(device_num);
	//printf("processing block with Device: %s\n", device->getName().c_str());

	sph_keccak512_context	 ctx_keccak;
	sph_keccak512_init(&ctx_keccak);
	sph_keccak512(&ctx_keccak, &block->version, 80);

	q->enqueueWriteBuffer(u, ctx_keccak.u.narrow, 25*sizeof(cl_ulong));
	q->enqueueWriteBuffer(buff, ctx_keccak.buf, 4);
	q->enqueueWriteBuffer(target, &tmp_target, sizeof(cl_uint));

	// measure time
	for (uint32 n = 0; n < NUM_STEPS; n++)
	{
#ifdef MEASURE_TIME
		uint32 begin = getTimeMilliseconds();
#endif
		if( block->height != monitorCurrentBlockHeight )
			break;
		//keccak
		tmp_begin_nonce = n * STEP_SIZE;
		q->enqueueWriteBuffer(begin_nonce, &tmp_begin_nonce, sizeof(cl_uint));
		tmp_out_count = 0;
		q->enqueueWriteBuffer(out_count, &tmp_out_count, sizeof(cl_uint));
		q->enqueueKernel1D(kernel_single_noinit, STEP_SIZE, wg_size);
		q->enqueueReadBuffer(out, out_tmp, sizeof(cl_uint) * 255);
		q->enqueueReadBuffer(out_count, &tmp_out_count, sizeof(cl_uint));
		q->finish();

		for (int i = 0; i < tmp_out_count; i++) {
			totalShareCount++;
			block->nonce = out_tmp[i];
			xptMiner_submitShare(block);
		}

		totalCollisionCount += STEP_SIZE;
#ifdef MEASURE_TIME
		uint32 end = getTimeMilliseconds();
		printf("Elapsed time: %d ms\n", (end-begin));
#endif

#ifdef VALIDATE_ALGORITHMS
		uint32 begin_validation = getTimeMilliseconds();

		cl_ulong *tmp_hashes = new cl_ulong[8 * STEP_SIZE];
		q->enqueueReadBuffer(hashes, tmp_hashes,
				sizeof(cl_ulong) * 8 * STEP_SIZE);
		q->finish();

		int aaa = 0;
		for (int i = 0; i < STEP_SIZE; i++) {
			cl_ulong * hhh = tmp_hashes+(i*8);
			if( *(cl_uint*)((cl_uchar*)hhh+28) <= tmp_target )
			{
				aaa++;
			}
		}

		if (aaa != tmp_out_count) {
			printf ("************* ERRO ****************\n");
			exit(0);
		}


		// validator
		block->nonce = (n*STEP_SIZE);
		for (int f2 = 0; f2 < STEP_SIZE; f2++) {
			sph_keccak512_context	 ctx_keccak;
			sph_shavite512_context	 ctx_shavite;
			sph_metis512_context	 ctx_metis;
			cl_ulong hash0[8];
			cl_ulong hash1[8];
			cl_ulong hash2[8];
			cl_ulong *hash1_2;
			cl_ulong *hash2_2;

			sph_keccak512_init(&ctx_keccak);
			sph_shavite512_init(&ctx_shavite);
			sph_metis512_init(&ctx_metis);
			sph_keccak512(&ctx_keccak, &block->version, 80);
			sph_keccak512_close(&ctx_keccak, hash0);
			sph_shavite512(&ctx_shavite, hash0, 64);
			sph_shavite512_close(&ctx_shavite, hash1);
			sph_metis512(&ctx_metis, hash1, 64);
			sph_metis512_close(&ctx_metis, hash2);

			hash2_2 = tmp_hashes+(f2*8);

			for (int i = 0; i < 8; i++) {
				if (hash2[i] != hash2_2[i]) {
					printf ("**** Hashes do not match %d/%d %x %x\n", f2, i, hash0[i], hash2_2[i]);
				}
			}

//			for (int i = 0; i < 8; i++) {
//				if (hash0[i] != hash2_2[i]) {
//					printf ("**** Hashes do not match %d/%d %lx %lx\n", f, i, hash0[i], hash2_2[i]);
//
//				}
//				if (ctx_keccak.buf[i] = hash2_2[i]) {
//					printf ("**** Hashes do not match %d/%d %x %x\n", f, i, ctx_keccak.buf[i], hash2_2[i]);
//				}
//			}
//			if (f == 32) exit(0);

			block->nonce++;
		}
		delete tmp_hashes;
		block->nonce = 0;
		uint32 end_validation = getTimeMilliseconds();
		printf("Validation time: %d ms\n", (end_validation-begin_validation));
#endif
	}

}
