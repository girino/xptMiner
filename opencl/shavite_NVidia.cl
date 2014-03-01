
#pragma OPENCL EXTENSION cl_khr_byte_addressable_store : enable
#ifdef _ECLIPSE_OPENCL_HEADER
#   include "OpenCLKernel.hpp"
#endif

typedef struct {
    unsigned char buf[128];    /* first field, for alignment */
    uint h[16];
} __attribute__ ((aligned)) shavite_context;

#define C32(x)  ((uint)(x))
#define AESx(x) C32(x)

__constant const uint IV512shavite[] __attribute__ ((aligned)) = {
    C32(0x72FCCDD8), C32(0x79CA4727), C32(0x128A077B), C32(0x40D55AEC),
    C32(0xD1901A06), C32(0x430AE307), C32(0xB29F5CD1), C32(0xDF07FBFC),
    C32(0x8E45D73D), C32(0x681AB538), C32(0xBDE86578), C32(0xDD577E47),
    C32(0xE275EADE), C32(0x502D9FCD), C32(0xB9357178), C32(0x022A4B9A)
};

void
shavite_init(shavite_context *sc)
{
    sc->h[0x0] = 0x72FCCDD8;
    sc->h[0x1] = 0x79CA4727;
    sc->h[0x2] = 0x128A077B;
    sc->h[0x3] = 0x40D55AEC;
    sc->h[0x4] = 0xD1901A06;
    sc->h[0x5] = 0x430AE307;
    sc->h[0x6] = 0xB29F5CD1;
    sc->h[0x7] = 0xDF07FBFC;
    sc->h[0x8] = 0x8E45D73D;
    sc->h[0x9] = 0x681AB538;
    sc->h[0xA] = 0xBDE86578;
    sc->h[0xB] = 0xDD577E47;
    sc->h[0xC] = 0xE275EADE;
    sc->h[0xD] = 0x502D9FCD;
    sc->h[0xE] = 0xB9357178;
    sc->h[0xF] = 0x022A4B9A;
}

#define SPH_T32(x)  ((x) & SPH_C32(0xFFFFFFFF))
#define SPH_C32(x)  ((uint)(x))
#define AESx(x)     SPH_C32(x)
#define SHAVITE_LOOKUP0     local_AES0
#define SHAVITE_LOOKUP1     local_AES1
#define SHAVITE_LOOKUP2     local_AES2
#define SHAVITE_LOOKUP3     local_AES3


#define AES_ROUND_LE(X, Y)   { \
        (Y.s0)  = SHAVITE_LOOKUP0[(uchar)((X.s0)      )]; \
        (Y.s1)  = SHAVITE_LOOKUP0[(uchar)((X.s1)      )]; \
        (Y.s2)  = SHAVITE_LOOKUP0[(uchar)((X.s2)      )]; \
        (Y.s3)  = SHAVITE_LOOKUP0[(uchar)((X.s3)      )]; \
        \
        (Y.s0) ^= SHAVITE_LOOKUP1[(uchar)((X.s1) >>  8)]; \
        (Y.s1) ^= SHAVITE_LOOKUP1[(uchar)((X.s2) >>  8)]; \
        (Y.s2) ^= SHAVITE_LOOKUP1[(uchar)((X.s3) >>  8)]; \
        (Y.s3) ^= SHAVITE_LOOKUP1[(uchar)((X.s0) >>  8)]; \
        \
        (Y.s0) ^= SHAVITE_LOOKUP2[(uchar)((X.s2) >> 16)]; \
        (Y.s1) ^= SHAVITE_LOOKUP2[(uchar)((X.s3) >> 16)]; \
        (Y.s2) ^= SHAVITE_LOOKUP2[(uchar)((X.s0) >> 16)]; \
        (Y.s3) ^= SHAVITE_LOOKUP2[(uchar)((X.s1) >> 16)]; \
        \
        (Y.s0) ^= SHAVITE_LOOKUP3[(uchar)((X.s3) >> 24)]; \
        (Y.s1) ^= SHAVITE_LOOKUP3[(uchar)((X.s0) >> 24)]; \
        (Y.s2) ^= SHAVITE_LOOKUP3[(uchar)((X.s1) >> 24)]; \
        (Y.s3) ^= SHAVITE_LOOKUP3[(uchar)((X.s2) >> 24)]; \
    }

#define AES_ROUND_NOKEY_LE(X, Y) \
    AES_ROUND_LE(X, Y)

#define AES_ROUND_NOKEY(x)   { \
        uint4 t = x; \
        AES_ROUND_NOKEY_LE(t, x); \
    }

#define KEY_EXPAND_ELT(k)   { \
        AES_ROUND_NOKEY(k); \
        k = k.s1230; \
    }


//#define sph_dec32le_aligned(src) ((uint)(((const unsigned char *)(src))[0]) \
//		| ((uint)(((const unsigned char *)(src))[1]) << 8) \
//		| ((uint)(((const unsigned char *)(src))[2]) << 16) \
//		| ((uint)(((const unsigned char *)(src))[3]) << 24))

#define sph_dec32le_aligned(x)  (*((uint*)(x)))
#define enc32le(dst, val)       (*((HASHES_MODIFIER uint*)(dst)) = (val))

void
shavite_core_64(shavite_context *sc, HASHES_MODIFIER const void *data)
{
    ((ulong8*)sc->buf)[0] = *((HASHES_MODIFIER ulong8*)data);
    ((ulong8*)sc->buf)[1] = 0;
}

void
shavite_close(shavite_context *sc, HASHES_MODIFIER void *dst,
              local uint* restrict SHAVITE_LOOKUP0,
              local uint* restrict SHAVITE_LOOKUP1,
              local uint* restrict SHAVITE_LOOKUP2,
              local uint* restrict SHAVITE_LOOKUP3
              )
{
    unsigned char *buf;
    buf = sc->buf;
    buf[64] = 0x80;
    //enc32le(buf + 110, 512); -> buff[110-113] = (0, 2, 0, 0);
    buf[111] = 2;
    buf[126] = 512;
    buf[127] = 2;


    // Shavite core "c512"
    const void *msg = buf;
    //uint p0, p1, p2, p3, p4, p5, p6, p7;
    //uint p8, p9, pA, pB, pC, pD, pE, pF;
    uint4 p0_3, p4_7, p8_B, pC_F;

    //uint x0, x1, x2, x3;
    uint4 x;

    //uint rk00, rk01, rk02, rk03, rk04, rk05, rk06, rk07;
    //uint rk08, rk09, rk0A, rk0B, rk0C, rk0D, rk0E, rk0F;
    //uint rk10, rk11, rk12, rk13, rk14, rk15, rk16, rk17;
    //uint rk18, rk19, rk1A, rk1B, rk1C, rk1D, rk1E, rk1F;
    uint4 rk00_03, rk04_07, rk08_0B, rk0C_0F;
    uint4 rk10_13, rk14_17, rk18_1B, rk1C_1F;

    int r;

    p0_3.s0 = sc->h[0x0];
    p0_3.s1 = sc->h[0x1];
    p0_3.s2 = sc->h[0x2];
    p0_3.s3 = sc->h[0x3];
    p4_7.s0 = sc->h[0x4];
    p4_7.s1 = sc->h[0x5];
    p4_7.s2 = sc->h[0x6];
    p4_7.s3 = sc->h[0x7];
    p8_B.s0 = sc->h[0x8];
    p8_B.s1 = sc->h[0x9];
    p8_B.s2 = sc->h[0xA];
    p8_B.s3 = sc->h[0xB];
    pC_F.s0 = sc->h[0xC];
    pC_F.s1 = sc->h[0xD];
    pC_F.s2 = sc->h[0xE];
    pC_F.s3 = sc->h[0xF];
    /* round 0 */
    rk00_03.s0 = sph_dec32le_aligned((const unsigned char *)msg +   0);
    rk00_03.s1 = sph_dec32le_aligned((const unsigned char *)msg +   4);
    rk00_03.s2 = sph_dec32le_aligned((const unsigned char *)msg +   8);
    rk00_03.s3 = sph_dec32le_aligned((const unsigned char *)msg +  12);
    x = p4_7 ^ rk00_03;
    AES_ROUND_NOKEY(x);
    rk04_07.s0 = sph_dec32le_aligned((const unsigned char *)msg +  16);
    rk04_07.s1 = sph_dec32le_aligned((const unsigned char *)msg +  20);
    rk04_07.s2 = sph_dec32le_aligned((const unsigned char *)msg +  24);
    rk04_07.s3 = sph_dec32le_aligned((const unsigned char *)msg +  28);
    x ^= rk04_07;
    AES_ROUND_NOKEY(x)
    rk08_0B.s0 = sph_dec32le_aligned((const unsigned char *)msg +  32);
    rk08_0B.s1 = sph_dec32le_aligned((const unsigned char *)msg +  36);
    rk08_0B.s2 = sph_dec32le_aligned((const unsigned char *)msg +  40);
    rk08_0B.s3 = sph_dec32le_aligned((const unsigned char *)msg +  44);
    x ^= rk08_0B;
    AES_ROUND_NOKEY(x)
    rk0C_0F.s0 = sph_dec32le_aligned((const unsigned char *)msg +  48);
    rk0C_0F.s1 = sph_dec32le_aligned((const unsigned char *)msg +  52);
    rk0C_0F.s2 = sph_dec32le_aligned((const unsigned char *)msg +  56);
    rk0C_0F.s3 = sph_dec32le_aligned((const unsigned char *)msg +  60);
    x ^= rk0C_0F;
    AES_ROUND_NOKEY(x)
    p0_3 ^= x;
    rk10_13.s0 = sph_dec32le_aligned((const unsigned char *)msg +  64);
    rk10_13.s1 = sph_dec32le_aligned((const unsigned char *)msg +  68);
    rk10_13.s2 = sph_dec32le_aligned((const unsigned char *)msg +  72);
    rk10_13.s3 = sph_dec32le_aligned((const unsigned char *)msg +  76);
    x = pC_F ^ rk10_13;
    AES_ROUND_NOKEY(x)
    rk14_17.s0 = sph_dec32le_aligned((const unsigned char *)msg +  80);
    rk14_17.s1 = sph_dec32le_aligned((const unsigned char *)msg +  84);
    rk14_17.s2 = sph_dec32le_aligned((const unsigned char *)msg +  88);
    rk14_17.s3 = sph_dec32le_aligned((const unsigned char *)msg +  92);
    x ^= rk14_17;
    AES_ROUND_NOKEY(x)
    rk18_1B.s0 = sph_dec32le_aligned((const unsigned char *)msg +  96);
    rk18_1B.s1 = sph_dec32le_aligned((const unsigned char *)msg + 100);
    rk18_1B.s2 = sph_dec32le_aligned((const unsigned char *)msg + 104);
    rk18_1B.s3 = sph_dec32le_aligned((const unsigned char *)msg + 108);
    x ^= rk18_1B;
    AES_ROUND_NOKEY(x)
    rk1C_1F.s0 = sph_dec32le_aligned((const unsigned char *)msg + 112);
    rk1C_1F.s1 = sph_dec32le_aligned((const unsigned char *)msg + 116);
    rk1C_1F.s2 = sph_dec32le_aligned((const unsigned char *)msg + 120);
    rk1C_1F.s3 = sph_dec32le_aligned((const unsigned char *)msg + 124);
    x ^= rk1C_1F;
    AES_ROUND_NOKEY(x)
    p8_B ^= x;

#pragma unroll
    for (r = 0; r < 3; r ++) {
        /* round 1, 5, 9 */
        KEY_EXPAND_ELT(rk00_03);
        rk00_03 ^= rk1C_1F;
        if (r == 0) {
            rk00_03.s0 ^= 512;
            rk00_03.s3 ^= 0xFFFFFFFF;
        }
        x = p0_3 ^ rk00_03;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk04_07);
        rk04_07 ^= rk00_03;
        if (r == 1) {
            rk04_07.s3 ^= 0xfffffdff;
        }
        x ^= rk04_07;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk08_0B);
        rk08_0B ^= rk04_07;
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk0C_0F);
        rk0C_0F ^= rk08_0B;
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x)
        pC_F ^= x;
        KEY_EXPAND_ELT(rk10_13);
        rk10_13 ^= rk0C_0F;
        x = p8_B ^ rk10_13;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk14_17);
        rk14_17 ^= rk10_13;
        x ^= rk14_17;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk18_1B);
        rk18_1B ^= rk14_17;
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk1C_1F);
        rk1C_1F ^= rk18_1B;
        if (r == 2) {
            rk1C_1F.s2 ^= 512;
            rk1C_1F.s3 ^= 0xffffffff;
        }
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x)
        p4_7 ^= x;
        /* round 2, 6, 10 */
        rk00_03.s0 ^= rk18_1B.s1;
        rk00_03.s1 ^= rk18_1B.s2;
        rk00_03.s2 ^= rk18_1B.s3;
        rk00_03.s3 ^= rk1C_1F.s0;
        x = pC_F ^ rk00_03;
        AES_ROUND_NOKEY(x)
        rk04_07.s0 ^= rk1C_1F.s1;
        rk04_07.s1 ^= rk1C_1F.s2;
        rk04_07.s2 ^= rk1C_1F.s3;
        rk04_07.s3 ^= rk00_03.s0;
        x ^= rk04_07;
        AES_ROUND_NOKEY(x)
        rk08_0B.s0 ^= rk00_03.s1;
        rk08_0B.s1 ^= rk00_03.s2;
        rk08_0B.s2 ^= rk00_03.s3;
        rk08_0B.s3 ^= rk04_07.s0;
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x)
        rk0C_0F.s0 ^= rk04_07.s1;
        rk0C_0F.s1 ^= rk04_07.s2;
        rk0C_0F.s2 ^= rk04_07.s3;
        rk0C_0F.s3 ^= rk08_0B.s0;
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x)
        p8_B ^= x;
        rk10_13.s0 ^= rk08_0B.s1;
        rk10_13.s1 ^= rk08_0B.s2;
        rk10_13.s2 ^= rk08_0B.s3;
        rk10_13.s3 ^= rk0C_0F.s0;
        x = p4_7 ^ rk10_13;
        AES_ROUND_NOKEY(x)
        rk14_17.s0 ^= rk0C_0F.s1;
        rk14_17.s1 ^= rk0C_0F.s2;
        rk14_17.s2 ^= rk0C_0F.s3;
        rk14_17.s3 ^= rk10_13.s0;
        x ^= rk14_17;
        AES_ROUND_NOKEY(x)
        rk18_1B.s0 ^= rk10_13.s1;
        rk18_1B.s1 ^= rk10_13.s2;
        rk18_1B.s2 ^= rk10_13.s3;
        rk18_1B.s3 ^= rk14_17.s0;
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x)
        rk1C_1F.s0 ^= rk14_17.s1;
        rk1C_1F.s1 ^= rk14_17.s2;
        rk1C_1F.s2 ^= rk14_17.s3;
        rk1C_1F.s3 ^= rk18_1B.s0;
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x)
        p0_3 ^= x;
        /* round 3, 7, 11 */
        KEY_EXPAND_ELT(rk00_03);
        rk00_03 ^= rk1C_1F;
        x = p8_B ^ rk00_03;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk04_07);
        rk04_07 ^= rk00_03;
        x ^= rk04_07;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk08_0B);
        rk08_0B ^= rk04_07;
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk0C_0F);
        rk0C_0F ^= rk08_0B;
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x)
        p4_7 ^= x;
        KEY_EXPAND_ELT(rk10_13);
        rk10_13 ^= rk0C_0F;
        x = p0_3 ^ rk10_13;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk14_17);
        rk14_17 ^= rk10_13;
        x ^= rk14_17;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk18_1B);
        rk18_1B ^= rk14_17;
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x)
        KEY_EXPAND_ELT(rk1C_1F);
        rk1C_1F ^= rk18_1B;
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x)
        pC_F ^= x;
        /* round 4, 8, 12 */
        rk00_03.s0 ^= rk18_1B.s1;
        rk00_03.s1 ^= rk18_1B.s2;
        rk00_03.s2 ^= rk18_1B.s3;
        rk00_03.s3 ^= rk1C_1F.s0;
        x = p4_7 ^ rk00_03;
        AES_ROUND_NOKEY(x)
        rk04_07.s0 ^= rk1C_1F.s1;
        rk04_07.s1 ^= rk1C_1F.s2;
        rk04_07.s2 ^= rk1C_1F.s3;
        rk04_07.s3 ^= rk00_03.s0;
        x ^= rk04_07;
        AES_ROUND_NOKEY(x)
        rk08_0B.s0 ^= rk00_03.s1;
        rk08_0B.s1 ^= rk00_03.s2;
        rk08_0B.s2 ^= rk00_03.s3;
        rk08_0B.s3 ^= rk04_07.s0;
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x)
        rk0C_0F.s0 ^= rk04_07.s1;
        rk0C_0F.s1 ^= rk04_07.s2;
        rk0C_0F.s2 ^= rk04_07.s3;
        rk0C_0F.s3 ^= rk08_0B.s0;
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x)
        p0_3 ^= x;
        rk10_13.s0 ^= rk08_0B.s1;
        rk10_13.s1 ^= rk08_0B.s2;
        rk10_13.s2 ^= rk08_0B.s3;
        rk10_13.s3 ^= rk0C_0F.s0;
        x = pC_F ^ rk10_13;
        AES_ROUND_NOKEY(x)
        rk14_17.s0 ^= rk0C_0F.s1;
        rk14_17.s1 ^= rk0C_0F.s2;
        rk14_17.s2 ^= rk0C_0F.s3;
        rk14_17.s3 ^= rk10_13.s0;
        x ^= rk14_17;
        AES_ROUND_NOKEY(x)
        rk18_1B.s0 ^= rk10_13.s1;
        rk18_1B.s1 ^= rk10_13.s2;
        rk18_1B.s2 ^= rk10_13.s3;
        rk18_1B.s3 ^= rk14_17.s0;
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x)
        rk1C_1F.s0 ^= rk14_17.s1;
        rk1C_1F.s1 ^= rk14_17.s2;
        rk1C_1F.s2 ^= rk14_17.s3;
        rk1C_1F.s3 ^= rk18_1B.s0;
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x)
        p8_B ^= x;
    }
    /* round 13 */
    KEY_EXPAND_ELT(rk00_03);
    rk00_03 ^= rk1C_1F;
    x = p0_3 ^ rk00_03;
    AES_ROUND_NOKEY(x)
    KEY_EXPAND_ELT(rk04_07);
    rk04_07 ^= rk00_03;
    x ^= rk04_07;
    AES_ROUND_NOKEY(x)
    KEY_EXPAND_ELT(rk08_0B);
    rk08_0B ^= rk04_07;
    x ^= rk08_0B;
    AES_ROUND_NOKEY(x)
    KEY_EXPAND_ELT(rk0C_0F);
    rk0C_0F ^= rk08_0B;
    x ^= rk0C_0F;
    AES_ROUND_NOKEY(x)
    pC_F ^= x;
    KEY_EXPAND_ELT(rk10_13);
    rk10_13 ^= rk0C_0F;
    x = p8_B ^ rk10_13;
    AES_ROUND_NOKEY(x)
    KEY_EXPAND_ELT(rk14_17);
    rk14_17 ^= rk10_13;
    x ^= rk14_17;
    AES_ROUND_NOKEY(x)
    KEY_EXPAND_ELT(rk18_1B);
    rk18_1B.s0 ^= rk14_17.s0;
    rk18_1B.s1 ^= rk14_17.s1 ^ 512;
    rk18_1B.s2 ^= rk14_17.s2;
    rk18_1B.s3 ^= rk14_17.s3 ^ 0xffffffff;
    x ^= rk18_1B;
    AES_ROUND_NOKEY(x)
    KEY_EXPAND_ELT(rk1C_1F);
    rk1C_1F ^= rk18_1B;
    x ^= rk1C_1F;
    AES_ROUND_NOKEY(x)
    p4_7 ^= x;
    sc->h[0x0] ^= p8_B.s0;
    sc->h[0x1] ^= p8_B.s1;
    sc->h[0x2] ^= p8_B.s2;
    sc->h[0x3] ^= p8_B.s3;
    sc->h[0x4] ^= pC_F.s0;
    sc->h[0x5] ^= pC_F.s1;
    sc->h[0x6] ^= pC_F.s2;
    sc->h[0x7] ^= pC_F.s3;
    sc->h[0x8] ^= p0_3.s0;
    sc->h[0x9] ^= p0_3.s1;
    sc->h[0xA] ^= p0_3.s2;
    sc->h[0xB] ^= p0_3.s3;
    sc->h[0xC] ^= p4_7.s0;
    sc->h[0xD] ^= p4_7.s1;
    sc->h[0xE] ^= p4_7.s2;
    sc->h[0xF] ^= p4_7.s3;


    // Shavite close
    #pragma unroll
    for (int u = 0; u < 16; u ++)
        enc32le((HASHES_MODIFIER unsigned char *)dst + (u << 2), sc->h[u]);
}

void
shavite(HASHES_MODIFIER ulong* restrict in_out,
        local uint* restrict local_AES0,
        local uint* restrict local_AES1,
        local uint* restrict local_AES2,
        local uint* restrict local_AES3)
{
	shavite_context	 ctx_shavite;
//	ulong hash0[8];
//	ulong hash1[8];

	// prepares data
//#pragma unroll
//	for (int i = 0; i < 8; i++) {
//		hash0[i] = in_out[i];
//	}

	shavite_init(&ctx_shavite);
	shavite_core_64(&ctx_shavite, in_out);
	shavite_close(&ctx_shavite, in_out, local_AES0, local_AES1, local_AES2, local_AES3);

//#pragma unroll
//	for (int i = 0; i < 8; i++) {
//		in_out[i] = hash1[i];
//	}
}

