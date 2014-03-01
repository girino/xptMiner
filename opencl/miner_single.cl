
#ifdef __ECLIPSE_EDITOR__
#include "OpenCLKernel.hpp"
#include "common.cl"
#endif

#define KERNEL_ATTRIB __attribute__(( ))

//	kernel_single_noinit->resetArgs();
//	kernel_single_noinit->addGlobalArg(u);
//	kernel_single_noinit->addGlobalArg(buff);
//	kernel_single_noinit->addLocalArg(8*wg_size*sizeof(cl_uint));
//	kernel_single_noinit->addGlobalArg(shavite_lookup);
//	kernel_single_noinit->addGlobalArg(fugue_lookup);
//	kernel_single_noinit->addGlobalArg(out);
//	kernel_single_noinit->addGlobalArg(out_count);
//	kernel_single_noinit->addGlobalArg(begin_nonce);
//	kernel_single_noinit->addGlobalArg(target);


kernel KERNEL_ATTRIB void 
single_noinit(constant ulong* restrict wide,
                   constant uint*  restrict buf,
                   local    ulong* restrict hashes,
              	   global   uint*  restrict AES,
                   global   uint*  restrict mixtab,
                   global   uint*  restrict out,
                   global   uint*  restrict outcount,
                   global   uint*  restrict begin_nonce,
                   global   uint*  restrict target)
{
    size_t id = get_global_id(0);
    size_t lid = get_local_id(0);
    uint nonce = (uint)id + *begin_nonce;
    // temp hash pointer
    local ulong* hash = hashes+(8*lid);
    // Copy global lookup table into local memory
    local uint shavite_lookup0[256];
    local uint shavite_lookup1[256];
    local uint shavite_lookup2[256];
    local uint shavite_lookup3[256];
    //local uint local_mixtab[1024];
    local uint local_mixtab0[256];
    local uint local_mixtab1[256];
    local uint local_mixtab2[256];
    local uint local_mixtab3[256];

	event_t eshavite;
	eshavite = async_work_group_copy(shavite_lookup0, AES, 256, 0);
	eshavite = async_work_group_copy(shavite_lookup1, AES+256, 256, eshavite);
	eshavite = async_work_group_copy(shavite_lookup2, AES+512, 256, eshavite);
	eshavite = async_work_group_copy(shavite_lookup3, AES+768, 256, eshavite);
    event_t efugue;
    efugue = async_work_group_copy (local_mixtab0, mixtab, 256, 0);
    efugue = async_work_group_copy (local_mixtab1, mixtab+256, 256, efugue);
    efugue = async_work_group_copy (local_mixtab2, mixtab+512, 256, efugue);
    efugue = async_work_group_copy (local_mixtab3, mixtab+768, 256, efugue);


    // keccak
    keccak(wide, buf, nonce, hash);
    wait_group_events(1, &eshavite);
    shavite((local uint *)hash,
            shavite_lookup0,
            shavite_lookup1,
            shavite_lookup2,
            shavite_lookup3);
    wait_group_events(1, &efugue);
    metis((local uint *)hash,
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

    if( *(local uint*)((local uchar*)hash + 28) <= *target )
    {
        out[atomic_inc(outcount)] = nonce;
    }

}

