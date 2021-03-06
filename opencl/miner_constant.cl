
#ifdef __ECLIPSE_EDITOR__
#include "OpenCLKernel.hpp"
#include "common.cl"
#include "tables.cl"
#endif

#define KERNEL_ATTRIB __attribute__(( ))

kernel KERNEL_ATTRIB void
metiscoin_process(constant ulong* wide,
                  constant char*  buf,
                  global   uint*  out,
                  global   uint*  outcount,
                   uint   begin_nonce,
                   uint   target,
                  global   uint*  restrict AES0,
                  global   uint*  restrict AES1,
                  global   uint*  restrict AES2,
                  global   uint*  restrict AES3,
                  global   uint*  restrict mixtab0,
                  global   uint*  restrict mixtab1,
                  global   uint*  restrict mixtab2,
                  global   uint*  restrict mixtab3)
{
    /*
    uint nonce = begin_nonce + get_global_id(0);
    ulong hash_temp[8];

    // Copy all lookup tables to local memory
    // Requires at least (8 * 256 * 4) bytes = 8 kb
    local uint shavite_lookup0[256];
    local uint shavite_lookup1[256];
    local uint shavite_lookup2[256];
    local uint shavite_lookup3[256];
    local uint metis_lookup0[256];
    local uint metis_lookup1[256];
    local uint metis_lookup2[256];
    local uint metis_lookup3[256];
    event_t e;
    e = async_work_group_copy(shavite_lookup0, AES0,    256, 0);
    e = async_work_group_copy(shavite_lookup1, AES1,    256, e);
    e = async_work_group_copy(shavite_lookup2, AES2,    256, e);
    e = async_work_group_copy(shavite_lookup3, AES3,    256, e);
    e = async_work_group_copy(metis_lookup0,   mixtab0, 256, e);
    e = async_work_group_copy(metis_lookup1,   mixtab1, 256, e);
    e = async_work_group_copy(metis_lookup2,   mixtab2, 256, e);
    e = async_work_group_copy(metis_lookup3,   mixtab3, 256, e);
    wait_group_events(1, &e);


    // keccak (resume from passed state)
    keccak(wide, buf, nonce, hash_temp);

    // shavite
    //shavite_init(&ctx_shavite);
    //shavite_core_64(&ctx_shavite, hash_temp);
    shavite((uint *)hash_temp,
            shavite_lookup0,
            shavite_lookup1,
            shavite_lookup2,
            shavite_lookup3);

    // metis
    metis((uint *)hash_temp,
          metis_lookup0,
          metis_lookup1,
          metis_lookup2,
          metis_lookup3);

    if( *(uint*)((uchar*)hash_temp+28) <= target )
    {
        out[atomic_inc(outcount)] = nonce;
    }
    */
}


kernel KERNEL_ATTRIB void 
keccak_step_noinit(constant ulong* restrict wide,
                   constant uint*  restrict buf,
                   global   ulong* restrict out,
                   constant uint*  restrict begin_nonce)
{
    size_t id = get_global_id(0);
    uint nonce = (uint)id + *begin_nonce;
    ulong hash[8];

    // keccak
    keccak(wide, buf, nonce, hash);

    #pragma unroll 8
    for (int i = 0; i < 8; i++) {
        out[(id * 8)+i] = hash[i];
    }
}


kernel KERNEL_ATTRIB void 
shavite_step(global ulong* restrict in_out)
{
    size_t id = get_global_id(0);
    ulong hash[8];

    // Copy global lookup table into local memory
    local uint shavite_lookup0[256];
    local uint shavite_lookup1[256];
    local uint shavite_lookup2[256];
    local uint shavite_lookup3[256];

	size_t lid = get_local_id(0);
	size_t lsz = get_local_size(0);
	if (lsz > 256) {
		if (lid < 256) {
			shavite_lookup0[lid] = AES0_c[lid];
			shavite_lookup1[lid] = AES1_c[lid];
			shavite_lookup2[lid] = AES2_c[lid];
			shavite_lookup3[lid] = AES3_c[lid];
		}
	} else {
		uint num_steps = 256/lsz;
#pragma unroll
		for (int i = 0; i < num_steps; i++) {
			size_t idx = lid+lsz*i;
			shavite_lookup0[idx] = AES0_c[idx];
			shavite_lookup1[idx] = AES1_c[idx];
			shavite_lookup2[idx] = AES2_c[idx];
			shavite_lookup3[idx] = AES3_c[idx];
		}
	}

	barrier(CLK_LOCAL_MEM_FENCE);

    // prepares data
    #pragma unroll 8
    for (int i = 0; i < 8; i++) {
        hash[i] = in_out[(id * 8)+i];
    }

    //shavite_init(&ctx_shavite);
    //shavite_core_64(&ctx_shavite, hash);
    shavite((uint *)hash,
            shavite_lookup0,
            shavite_lookup1,
            shavite_lookup2,
            shavite_lookup3);

    #pragma unroll 8
    for (int i = 0; i < 8; i++) {
        in_out[(id * 8)+i] = hash[i];
    }
}

kernel KERNEL_ATTRIB void
metis_step(global   ulong* restrict in,
           global   uint*  restrict out,
           global   uint*  restrict outcount,
           constant uint*  restrict begin_nonce,
           constant uint*  restrict target)
{
    size_t id = get_global_id(0);
    uint nonce = (uint)id + *begin_nonce;
    ulong hash[8];


    // Copy global lookup table into local memory
    local uint local_mixtab0[256];
    local uint local_mixtab1[256];
    local uint local_mixtab2[256];
    local uint local_mixtab3[256];

	size_t lid = get_local_id(0);
	size_t lsz = get_local_size(0);
	if (lsz > 256) {
		if (lid < 256) {
			local_mixtab0[lid] = mixtab0_c[lid];
			local_mixtab1[lid] = mixtab1_c[lid];
			local_mixtab2[lid] = mixtab2_c[lid];
			local_mixtab3[lid] = mixtab3_c[lid];
		}
	} else {
		uint num_steps = 256/lsz;
#pragma unroll
		for (int i = 0; i < num_steps; i++) {
			size_t idx = lid+lsz*i;
			local_mixtab0[idx] = mixtab0_c[idx];
			local_mixtab1[idx] = mixtab1_c[idx];
			local_mixtab2[idx] = mixtab2_c[idx];
			local_mixtab3[idx] = mixtab3_c[idx];
		}
	}
	// waits the copies
	barrier(CLK_LOCAL_MEM_FENCE);

    // prepares data
#pragma unroll 8
    for (int i = 0; i < 8; i++) {
        hash[i] = in[(id * 8)+i];
    }

    metis((uint *)hash,
          local_mixtab0,
          local_mixtab1,
          local_mixtab2,
          local_mixtab3);

    // for debug
#ifdef VALIDATE_ALGORITHMS
    for (int i = 0; i < 8; i++) {
            in[(id * 8)+i] = hash[i];
    }
#endif

    if( *(uint*)((uchar*)hash + 28) <= *target )
    {
        out[atomic_inc(outcount)] = nonce;
    }

}
