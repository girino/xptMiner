#ifdef _ECLIPSE_OPENCL_HEADER
#   include "OpenCLKernel.hpp"
#   include "keccak.cl"
#   include "shavite.cl"
#   include "metis.cl"
#   include "OpenCLKernel.hpp"
#endif

#include "opencl/common.cl"

//kernel void metiscoin_process_noinit(constant const ulong* u, constant const char* buff, global uint* out, global uint* outcount, uint begin_nonce, uint target) {
//
//	size_t id = get_global_id(0);
//	uint nonce = (uint)id + begin_nonce;
//	uint hnonce = nonce / 0x8000;
//	uint lnonce = nonce % 0x8000;
//	nonce = hnonce * 0x10000 + lnonce;
//
//	// locals
//	__local uint AES0[256];
//	__local uint AES1[256];
//	__local uint AES2[256];
//	__local uint AES3[256];
//
//	size_t lid = get_local_id(0);
//	size_t lsz = get_local_size(0);
//	if (lsz > 256) {
//		if (lid < 256) {
//			AES0[lid] = AES0_c[lid];
//			AES1[lid] = AES1_c[lid];
//			AES2[lid] = AES2_c[lid];
//			AES3[lid] = AES3_c[lid];
//		}
//	} else {
//		uint num_steps = 256/lsz;
//#pragma unroll
//		for (int i = 0; i < num_steps; i++) {
//			size_t idx = lid+lsz*i;
//			AES0[idx] = AES0_c[idx];
//			AES1[idx] = AES1_c[idx];
//			AES2[idx] = AES2_c[idx];
//			AES3[idx] = AES3_c[idx];
//		}
//	}
//	// waits the copies
//	barrier(CLK_LOCAL_MEM_FENCE);
//
//	ulong hash0[8];
//	ulong hash1[8];
//	ulong hash2[8];
//
//	// inits context
//	keccak_context	 ctx_keccak;
//	ctx_keccak.lim = 72;
//	ctx_keccak.ptr = 8;
//#pragma unroll
//	for (int i = 0; i < 4; i++) {
//		ctx_keccak.buf[i] = buff[i];
//	}
//	*((uint*)(ctx_keccak.buf+4)) = nonce;
//#pragma unroll
//	for (int i = 0; i < 25; i++) {
//		ctx_keccak.u.wide[i] = u[i];
//	}
//	// keccak
//	keccak_close(&ctx_keccak, hash0);
//
//	shavite_context ctx_shavite;
//	// shavite
//	shavite_init(&ctx_shavite);
//	shavite_core_64(&ctx_shavite, hash0);
//	shavite_close(&ctx_shavite, hash1, AES0, AES1, AES2, AES3);
//
//
//	if (lsz > 256) {
//		if (lid < 256) {
//			AES0[lid] = mixtab0_c[lid];
//			AES1[lid] = mixtab1_c[lid];
//			AES2[lid] = mixtab2_c[lid];
//			AES3[lid] = mixtab3_c[lid];
//		}
//	} else {
//		uint num_steps = 256/lsz;
//#pragma unroll
//		for (int i = 0; i < num_steps; i++) {
//			size_t idx = lid+lsz*i;
//			AES0[idx] = mixtab0_c[idx];
//			AES1[idx] = mixtab1_c[idx];
//			AES2[idx] = mixtab2_c[idx];
//			AES3[idx] = mixtab3_c[idx];
//		}
//	}
//	barrier(CLK_LOCAL_MEM_FENCE);
//
//	metis_context ctx_metis;
//	// metis
//	metis_init(&ctx_metis);
//	metis_core_64(&ctx_metis, hash1, AES0, AES1, AES2, AES3);
//	metis_close(&ctx_metis, hash2, AES0, AES1, AES2, AES3);
//
//	if( *(uint*)((uchar*)hash2+28) <= target )
//	{
//		uint pos = atomic_inc(outcount); //saves first pos for counter
//		out[pos] = nonce;
//	}
//
//}

//kernel void keccak_step(constant const uchar* in, global ulong* out, uint begin_nonce) {
//
//	size_t id = get_global_id(0);
//	uint nonce = (((uint)id) *2) + begin_nonce;
//	uint nonce_p_1 = nonce+1;
//
//	keccak_context	 ctx_keccak;
//	uchar2 data[80];
//	ulong2 hash[8];
//
//	// prepares data
//#pragma unroll
//	for (int i = 0; i < 80; i++) {
//		data[i] = in[i];
//	}
//	uchar * p = (uchar*)&nonce;
//	uchar * p1 = (uchar*)&nonce_p_1;
//#pragma unroll
//	for (int i = 0; i < 4; i++) {
//		data[76+i] = (p[i], p1[i]);
//	}
//
//	// keccak
//	keccak_init(&ctx_keccak);
//	keccak_core_80(&ctx_keccak, data);
//	keccak_close(&ctx_keccak, hash);
//
//#pragma unroll
//	for (int i = 0; i < 8; i++) {
//		out[(id * 8)+i] = hash[i].s0;
//		out[(id * 8)+i+8] = hash[i].s1;
//	}
//}

kernel void keccak_step_noinit(constant const ulong* u, constant const char* buff, global ulong* out, uint begin_nonce) {

	size_t id = get_global_id(0);
	uint nonce = (uint)id + begin_nonce;
	//uint hnonce = nonce / 0x8000;
	//uint lnonce = nonce % 0x8000;
	//nonce = hnonce * 0x10000 + lnonce;

	ulong hash[8];

	// inits context
	keccak_context	 ctx_keccak;
//	ctx_keccak.lim = 72;
//	ctx_keccak.ptr = 8;
#pragma unroll
	for (int i = 0; i < 4; i++) {
		ctx_keccak.buf[i] = buff[i];
	}
	*((uint*)(ctx_keccak.buf+4)) = nonce;
#pragma unroll
	for (int i = 0; i < 25; i++) {
		ctx_keccak.u.wide[i] = u[i];
	}

	// keccak
	keccak_close(&ctx_keccak, hash);

#pragma unroll
	for (int i = 0; i < 8; i++) {
		out[(id * 8)+i] = hash[i];
	}
}

kernel void shavite_step(global ulong* in_out) {

	size_t id = get_global_id(0);

	// locals
	__local uint AES0[256];
	__local uint AES1[256];
	__local uint AES2[256];
	__local uint AES3[256];

	size_t lid = get_local_id(0);
	size_t lsz = get_local_size(0);
	if (lsz > 256) {
		if (lid < 256) {
			AES0[lid] = AES0_c[lid];
			AES1[lid] = AES1_c[lid];
			AES2[lid] = AES2_c[lid];
			AES3[lid] = AES3_c[lid];
		}
	} else {
		uint num_steps = 256/lsz;
#pragma unroll
		for (int i = 0; i < num_steps; i++) {
			size_t idx = lid+lsz*i;
			AES0[idx] = AES0_c[idx];
			AES1[idx] = AES1_c[idx];
			AES2[idx] = AES2_c[idx];
			AES3[idx] = AES3_c[idx];
		}
	}
	// waits the copies

	barrier(CLK_LOCAL_MEM_FENCE);

	shavite_context	 ctx_shavite;
	ulong hash0[8];
	ulong hash1[8];

	// prepares data
#pragma unroll
	for (int i = 0; i < 8; i++) {
		hash0[i] = in_out[(id * 8)+i];
	}

	shavite_init(&ctx_shavite);
	shavite_core_64(&ctx_shavite, hash0);
	shavite_close(&ctx_shavite, hash1, AES0, AES1, AES2, AES3);

#pragma unroll
	for (int i = 0; i < 8; i++) {
		in_out[(id * 8)+i] = hash1[i];
	}
}

kernel void metis_step(global ulong* in, global uint* out, global uint* outcount, uint begin_nonce, uint target) {

	size_t id = get_global_id(0);
	uint nonce = (uint)id + begin_nonce;
	//uint hnonce = nonce / 0x8000;
	//uint lnonce = nonce % 0x8000;
	//nonce = hnonce * 0x10000 + lnonce;


	// locals
	__local uint mixtab0[256];
	__local uint mixtab1[256];
	__local uint mixtab2[256];
	__local uint mixtab3[256];


	size_t lid = get_local_id(0);
	size_t lsz = get_local_size(0);
	if (lsz > 256) {
		if (lid < 256) {
			mixtab0[lid] = mixtab0_c[lid];
			mixtab1[lid] = mixtab1_c[lid];
			mixtab2[lid] = mixtab2_c[lid];
			mixtab3[lid] = mixtab3_c[lid];
		}
	} else {
		uint num_steps = 256/lsz;
#pragma unroll
		for (int i = 0; i < num_steps; i++) {
			size_t idx = lid+lsz*i;
			mixtab0[idx] = mixtab0_c[idx];
			mixtab1[idx] = mixtab1_c[idx];
			mixtab2[idx] = mixtab2_c[idx];
			mixtab3[idx] = mixtab3_c[idx];
		}
	}
	// waits the copies
	barrier(CLK_LOCAL_MEM_FENCE);

	metis_context ctx_metis;
	ulong hash0[8];
	ulong hash1[8];

	// prepares data
#pragma unroll
	for (int i = 0; i < 8; i++) {
		hash0[i] = in[(id * 8)+i];
	}

	// metis
    metis_init(&ctx_metis);
    metis_core_and_close(&ctx_metis, hash0, hash1,
    		mixtab0,
    		mixtab1,
    		mixtab2,
    		mixtab3);

	// for debug
	for (int i = 0; i < 8; i++) {
		in[(id * 8)+i] = hash1[i];
	}

	if( *(uint*)((uchar*)hash1+28) <= target )
	{
		uint pos = atomic_inc(outcount);
		out[pos] = nonce;
	}

}
