#ifndef COMMON_CL_
#define COMMON_CL_

#ifndef __ENDIAN_LITTLE__
#error Your device is not little endian.  Only little endian devices are supported at this time.
#endif

#pragma OPENCL EXTENSION cl_khr_byte_addressable_store : enable

// .s3 = BYTE 0
// .s2 = BYTE 1
// .s1 = BYTE 2
// .s0 = BYTE 3
#define UINT_BYTE0(x)   ((uchar)((x) >> 24))
#define UINT_BYTE1(x)   ((uchar)((x) >> 16))
#define UINT_BYTE2(x)   ((uchar)((x) >>  8))
#define UINT_BYTE3(x)   ((uchar)((x)      ))

#define ULONG_BYTE0(x)  ((ulong)((x) >> 56))
#define ULONG_BYTE1(x)  ((ulong)((x) >> 48))
#define ULONG_BYTE2(x)  ((ulong)((x) >> 40))
#define ULONG_BYTE3(x)  ((ulong)((x) >> 32))
#define ULONG_BYTE4(x)  ((ulong)((x) >> 24))
#define ULONG_BYTE5(x)  ((ulong)((x) >> 16))
#define ULONG_BYTE6(x)  ((ulong)((x) >>  8))
#define ULONG_BYTE7(x)  ((ulong)((x)      ))

 uint4  MAKE_UINT4( uint a,  uint b,  uint c,  uint d) {  uint4 temp = ( (uint4)(a,b,c,d)); return temp; }
ulong4 MAKE_ULONG4(ulong a, ulong b, ulong c, ulong d) { ulong4 temp = ((ulong4)(a,b,c,d)); return temp; }
uchar4 MAKE_UCHAR4(uchar a, uchar b, uchar c, uchar d) { uchar4 temp = ((uchar4)(a,b,c,d)); return temp; }

#define SPH_C32(x)  ((uint)(x))
#define SPH_T32(x)  SPH_C32(x)
#define SPH_C64(x)  ((ulong)(x))
#define SPH_T64(x)  SPH_C64(x)

#define SPH_ROTL64(x, n)    rotate((ulong)(x), (ulong)(n))
#define SPH_ROTR64(x, n)    SPH_ROTL64(x, (64 - (n)))
#define SWAP32(x)   (as_uint(as_uchar4(x).s3210))
#define SWAP64(x)   (as_ulong(as_uchar8(x).s76543210))

#ifdef LOCAL_HASHES
#define HASHES_MODIFIER __local
#else
#define HASHES_MODIFIER
#endif

#endif
