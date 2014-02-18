#include "opencl/common.cl"

typedef struct {
    uint S[36];
} __attribute__ ((aligned)) metis_context;

#ifdef METIS_NOCOPY

#define  S0 S[ 0]
#define  S1 S[ 1]
#define  S2 S[ 2]
#define  S3 S[ 3]
#define  S4 S[ 4]
#define  S5 S[ 5]
#define  S6 S[ 6]
#define  S7 S[ 7]
#define  S8 S[ 8]
#define  S9 S[ 9]
#define S10 S[10]
#define S11 S[11]
#define S12 S[12]
#define S13 S[13]
#define S14 S[14]
#define S15 S[15]
#define S16 S[16]
#define S17 S[17]
#define S18 S[18]
#define S19 S[19]
#define S20 S[20]
#define S21 S[21]
#define S22 S[22]
#define S23 S[23]
#define S24 S[24]
#define S25 S[25]
#define S26 S[26]
#define S27 S[27]
#define S28 S[28]
#define S29 S[29]
#define S30 S[30]
#define S31 S[31]
#define S32 S[32]
#define S33 S[33]
#define S34 S[34]
#define S35 S[35]

#define DECLSTATE
#define READSTATE
#define WRITESTATE

#else

#define DECLSTATE \
    uint  S0,  S1,  S2,  S3; \
    uint  S4,  S5,  S6,  S7; \
    uint  S8,  S9, S10, S11; \
    uint S12, S13, S14, S15; \
    uint S16, S17, S18, S19; \
    uint S20, S21, S22, S23; \
    uint S24, S25, S26, S27; \
    uint S28, S29, S30, S31; \
    uint S32, S33, S34, S35;

#define READSTATE \
     S0 = S[ 0];  S1 = S[ 1];  S2 = S[ 2];  S3 = S[ 3]; \
     S4 = S[ 4];  S5 = S[ 5];  S6 = S[ 6];  S7 = S[ 7]; \
     S8 = S[ 8];  S9 = S[ 9]; S10 = S[10]; S11 = S[11]; \
    S12 = S[12]; S13 = S[13]; S14 = S[14]; S15 = S[15]; \
    S16 = S[16]; S17 = S[17]; S18 = S[18]; S19 = S[19]; \
    S20 = S[20]; S21 = S[21]; S22 = S[22]; S23 = S[23]; \
    S24 = S[24]; S25 = S[25]; S26 = S[26]; S27 = S[27]; \
    S28 = S[28]; S29 = S[29]; S30 = S[30]; S31 = S[31]; \
    S32 = S[32]; S33 = S[33]; S34 = S[34]; S35 = S[35];

#define WRITESTATE \
    S[ 0] =  S0; S[ 1] =  S1; S[ 2] =  S2; S[ 3] =  S3; \
    S[ 4] =  S4; S[ 5] =  S5; S[ 6] =  S6; S[ 7] =  S7; \
    S[ 8] =  S8; S[ 9] =  S9; S[10] = S10; S[11] = S11; \
    S[12] = S12; S[13] = S13; S[14] = S14; S[15] = S15; \
    S[16] = S16; S[17] = S17; S[18] = S18; S[19] = S19; \
    S[20] = S20; S[21] = S21; S[22] = S22; S[23] = S23; \
    S[24] = S24; S[25] = S25; S[26] = S26; S[27] = S27; \
    S[28] = S28; S[29] = S29; S[30] = S30; S[31] = S31; \
    S[32] = S32; S[33] = S33; S[34] = S34; S[35] = S35;

#endif

#define METIS_LOOKUP0 local_mixtab0
#define METIS_LOOKUP1 local_mixtab1
#define METIS_LOOKUP2 local_mixtab2
#define METIS_LOOKUP3 local_mixtab3


void metis_init(metis_context* sc) {
    sc->S[ 0] = 0;
    sc->S[ 1] = 0;
    sc->S[ 2] = 0;
    sc->S[ 3] = 0;
    sc->S[ 4] = 0;
    sc->S[ 5] = 0;
    sc->S[ 6] = 0;
    sc->S[ 7] = 0;
    sc->S[ 8] = 0;
    sc->S[ 9] = 0;
    sc->S[10] = 0;
    sc->S[11] = 0;
    sc->S[12] = 0;
    sc->S[13] = 0;
    sc->S[14] = 0;
    sc->S[15] = 0;
    sc->S[16] = 0;
    sc->S[17] = 0;
    sc->S[18] = 0;
    sc->S[19] = 0;
    sc->S[20] = 0x8807A57E;
    sc->S[21] = 0xE616AF75;
    sc->S[22] = 0xC5D3E4DB;
    sc->S[23] = 0xAC9AB027;
    sc->S[24] = 0xD915F117;
    sc->S[25] = 0xB6EECC54;
    sc->S[26] = 0x06E8020B;
    sc->S[27] = 0x4A92EFD1;
    sc->S[28] = 0xAAC6E2C9;
    sc->S[29] = 0xDDB21398;
    sc->S[30] = 0xCAE65838;
    sc->S[31] = 0x437F203F;
    sc->S[32] = 0x25EA78E7;
    sc->S[33] = 0x951FDDD6;
    sc->S[34] = 0xDA6ED11D;
    sc->S[35] = 0xE13E3567;
}

// Seriously, who the hell comes up with this?
#define TIX4(q, x00, x01, x04, x07, x08, x22, x24, x27, x30)   { \
        x22 ^= x00; \
        x00 = (q); \
        x08 ^= x00; \
        x01 ^= x24; \
        x04 ^= x27; \
        x07 ^= x30; \
    }

#define CMIX36(x00, x01, x02, x04, x05, x06, x18, x19, x20)   { \
        x00 ^= x04; \
        x01 ^= x05; \
        x02 ^= x06; \
        x18 ^= x04; \
        x19 ^= x05; \
        x20 ^= x06; \
    }

#define SMIX(x0, x1, x2, x3)   { \
    /* Consider computing "x" bytes free, but lookup is expensive. */  \
    /* Interleve table lookups to reduce memory bank conflicts.    */  \
    uint tmp;                              \
    uint c0, c1, c2, c3;                   \
    uint r0, r1, r2, r3;                   \
    c0  = METIS_LOOKUP0[as_uchar4(x0).s3]; \
    c1  = METIS_LOOKUP1[as_uchar4(x1).s2]; \
    c2  = METIS_LOOKUP2[as_uchar4(x2).s1]; \
    c3  = METIS_LOOKUP3[as_uchar4(x3).s0]; \
    \
    r1  = METIS_LOOKUP1[as_uchar4(x0).s2]; \
    r2  = METIS_LOOKUP2[as_uchar4(x1).s1]; \
    r3  = METIS_LOOKUP3[as_uchar4(x2).s0]; \
    r0  = METIS_LOOKUP0[as_uchar4(x3).s3]; \
    \
    c0 ^= r1;                              \
    c1 ^= r2;                              \
    c2 ^= r3;                              \
    c3 ^= r0;                              \
    \
    tmp = METIS_LOOKUP2[as_uchar4(x0).s1]; \
    c0 ^= tmp;                             \
    r2 ^= tmp;                             \
    tmp = METIS_LOOKUP3[as_uchar4(x1).s0]; \
    c1 ^= tmp;                             \
    r3 ^= tmp;                             \
    tmp = METIS_LOOKUP0[as_uchar4(x2).s3]; \
    c2 ^= tmp;                             \
    r0 ^= tmp;                             \
    tmp = METIS_LOOKUP1[as_uchar4(x3).s2]; \
    c3 ^= tmp;                             \
    r1 ^= tmp;                             \
    \
    tmp = METIS_LOOKUP3[as_uchar4(x0).s0]; \
    c0 ^= tmp;                             \
    r3 ^= tmp;                             \
    tmp = METIS_LOOKUP0[as_uchar4(x1).s3]; \
    c1 ^= tmp;                             \
    r0 ^= tmp;                             \
    tmp = METIS_LOOKUP1[as_uchar4(x2).s2]; \
    c2 ^= tmp;                             \
    r1 ^= tmp;                             \
    tmp = METIS_LOOKUP2[as_uchar4(x3).s1]; \
    c3 ^= tmp;                             \
    r2 ^= tmp;                             \
    \
    x0 =  ((c0 ^  r0)        & (0xFF000000))  \
        | ((c1 ^  r1)        & (0x00FF0000))  \
        | ((c2 ^  r2)        & (0x0000FF00))  \
        | ((c3 ^  r3)        & (0x000000FF)); \
    x1 =  ((c1 ^ (r0 <<  8)) & (0xFF000000))  \
        | ((c2 ^ (r1 <<  8)) & (0x00FF0000))  \
        | ((c3 ^ (r2 <<  8)) & (0x0000FF00))  \
        | ((c0 ^ (r3 >> 24)) & (0x000000FF)); \
    x2 =  ((c2 ^ (r0 << 16)) & (0xFF000000))  \
        | ((c3 ^ (r1 << 16)) & (0x00FF0000))  \
        | ((c0 ^ (r2 >> 16)) & (0x0000FF00))  \
        | ((c1 ^ (r3 >> 16)) & (0x000000FF)); \
    x3 =  ((c3 ^ (r0 << 24)) & (0xFF000000))  \
        | ((c0 ^ (r1 >>  8)) & (0x00FF0000))  \
        | ((c1 ^ (r2 >>  8)) & (0x0000FF00))  \
        | ((c2 ^ (r3 >>  8)) & (0x000000FF)); \
}


void metis_core_and_close(metis_context *sc, const unsigned char *cdata, void *dst,
                          local uint* restrict METIS_LOOKUP0,
                          local uint* restrict METIS_LOOKUP1,
                          local uint* restrict METIS_LOOKUP2,
                          local uint* restrict METIS_LOOKUP3
                          )
{
    uint* S = sc->S;
    DECLSTATE;
    READSTATE;

    TIX4(my_dec32be(cdata),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(my_dec32be(cdata+4), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(my_dec32be(cdata+8), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // x
    TIX4(my_dec32be(cdata+12),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(my_dec32be(cdata+16), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(my_dec32be(cdata+20), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    TIX4(my_dec32be(cdata+24),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(my_dec32be(cdata+28), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(my_dec32be(cdata+32), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // x
    TIX4(my_dec32be(cdata+36),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(my_dec32be(cdata+40), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(my_dec32be(cdata+44), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // x
    TIX4(my_dec32be(cdata+48),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(my_dec32be(cdata+52), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(my_dec32be(cdata+56), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // moved from close
    TIX4(my_dec32be(cdata+60),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(0, S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(512, S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);


    // METIS CLOSE
    #pragma unroll
    for (int i = 0; i < 2; i++) {
        // i =  0, 12
        CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
        SMIX(S33, S34, S35,  S0);
        // i =  1, 13
        CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
        SMIX(S30, S31, S32, S33);
        // i =  2, 14
        CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
        SMIX(S27, S28, S29, S30);
        // i =  3, 15
        CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
        SMIX(S24, S25, S26, S27);
        // i =  4, 16
        CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
        SMIX(S21, S22, S23, S24);
        // i =  5, 17
        CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
        SMIX(S18, S19, S20, S21);
        // i =  6, 18
        CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
        SMIX(S15, S16, S17, S18);
        // i =  7, 19
        CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
        SMIX(S12, S13, S14, S15);
        // i =  8, 20
        CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
        SMIX( S9, S10, S11, S12);
        // i =  9, 21
        CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
        SMIX( S6,  S7,  S8,  S9);
        // i = 10, 22
        CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
        SMIX( S3,  S4,  S5,  S6);
        // i = 11, 23
        CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
        SMIX( S0,  S1,  S2,  S3);
    }
    // i = 24
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    // i = 25
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    // i = 26
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    // i = 27
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    // i = 28
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    // i = 29
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    // i = 30
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    // i = 31
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);


    // i = 0
    S16 ^= S12; S21 ^= S12; S30 ^= S12;  S3 ^= S12;
    SMIX( S3,  S4,  S5,  S6);
     S7 ^=  S3; S13 ^=  S3; S21 ^=  S3; S30 ^=  S3;
    SMIX(S30, S31, S32, S33);
    S34 ^= S30;  S4 ^= S30; S13 ^= S30; S21 ^= S30;
    SMIX(S21, S22, S23, S24);
    S25 ^= S21; S31 ^= S21;  S4 ^= S21; S13 ^= S21;
    SMIX(S13, S14, S15, S16);
    // i = 1
    S17 ^= S13; S22 ^= S13; S31 ^= S13;  S4 ^= S13;
    SMIX( S4,  S5,  S6,  S7);
     S8 ^=  S4; S14 ^=  S4; S22 ^=  S4; S31 ^=  S4;
    SMIX(S31, S32, S33, S34);
    S35 ^= S31;  S5 ^= S31; S14 ^= S31; S22 ^= S31;
    SMIX(S22, S23, S24, S25);
    S26 ^= S22; S32 ^= S22;  S5 ^= S22; S14 ^= S22;
    SMIX(S14, S15, S16, S17);
    // i = 2
    S18 ^= S14; S23 ^= S14; S32 ^= S14;  S5 ^= S14;
    SMIX( S5,  S6,  S7,  S8);
     S9 ^=  S5; S15 ^=  S5; S23 ^=  S5; S32 ^=  S5;
    SMIX(S32, S33, S34, S35);
     S0 ^= S32;  S6 ^= S32; S15 ^= S32; S23 ^= S32;
    SMIX(S23, S24, S25, S26);
    S27 ^= S23; S33 ^= S23;  S6 ^= S23; S15 ^= S23;
    SMIX(S15, S16, S17, S18);
    // i = 3
    S19 ^= S15; S24 ^= S15; S33 ^= S15;  S6 ^= S15;
    SMIX( S6,  S7,  S8,  S9);
    S10 ^=  S6; S16 ^=  S6; S24 ^=  S6; S33 ^=  S6;
    SMIX(S33, S34, S35,  S0);
     S1 ^= S33;  S7 ^= S33; S16 ^= S33; S24 ^= S33;
    SMIX(S24, S25, S26, S27);
    S28 ^= S24; S34 ^= S24;  S7 ^= S24; S16 ^= S24;
    SMIX(S16, S17, S18, S19);
    // i = 4
    S20 ^= S16; S25 ^= S16; S34 ^= S16;  S7 ^= S16;
    SMIX( S7,  S8,  S9, S10);
    S11 ^=  S7; S17 ^=  S7; S25 ^=  S7; S34 ^=  S7;
    SMIX(S34, S35,  S0,  S1);
     S2 ^= S34;  S8 ^= S34; S17 ^= S34; S25 ^= S34;
    SMIX(S25, S26, S27, S28);
    S29 ^= S25; S35 ^= S25;  S8 ^= S25; S17 ^= S25;
    SMIX(S17, S18, S19, S20);
    // i = 5
    S21 ^= S17; S26 ^= S17; S35 ^= S17;  S8 ^= S17;
    SMIX( S8,  S9, S10, S11);
    S12 ^=  S8; S18 ^=  S8; S26 ^=  S8; S35 ^=  S8;
    SMIX(S35,  S0,  S1,  S2);
     S3 ^= S35;  S9 ^= S35; S18 ^= S35; S26 ^= S35;
    SMIX(S26, S27, S28, S29);
    S30 ^= S26;  S0 ^= S26;  S9 ^= S26; S18 ^= S26;
    SMIX(S18, S19, S20, S21);
    // i = 6
    S22 ^= S18; S27 ^= S18;  S0 ^= S18;  S9 ^= S18;
    SMIX( S9, S10, S11, S12);
    S13 ^=  S9; S19 ^=  S9; S27 ^=  S9;  S0 ^=  S9;
    SMIX( S0,  S1,  S2,  S3);
     S4 ^=  S0; S10 ^=  S0; S19 ^=  S0; S27 ^=  S0;
    SMIX(S27, S28, S29, S30);
    S31 ^= S27;  S1 ^= S27; S10 ^= S27; S19 ^= S27;
    SMIX(S19, S20, S21, S22);
    // i = 7
    S23 ^= S19; S28 ^= S19;  S1 ^= S19; S10 ^= S19;
    SMIX(S10, S11, S12, S13);
    S14 ^= S10; S20 ^= S10; S28 ^= S10;  S1 ^= S10;
    SMIX( S1,  S2,  S3,  S4);
     S5 ^=  S1; S11 ^=  S1; S20 ^=  S1; S28 ^=  S1;
    SMIX(S28, S29, S30, S31);
    S32 ^= S28;  S2 ^= S28; S11 ^= S28; S20 ^= S28;
    SMIX(S20, S21, S22, S23);
    // i = 8
    S24 ^= S20; S29 ^= S20;  S2 ^= S20; S11 ^= S20;
    SMIX(S11, S12, S13, S14);
    S15 ^= S11; S21 ^= S11; S29 ^= S11;  S2 ^= S11;
    SMIX( S2,  S3,  S4,  S5);
     S6 ^=  S2; S12 ^=  S2; S21 ^=  S2; S29 ^=  S2;
    SMIX(S29, S30, S31, S32);
    S33 ^= S29;  S3 ^= S29; S12 ^= S29; S21 ^= S29;
    SMIX(S21, S22, S23, S24);
    // i = 9
    S25 ^= S21; S30 ^= S21;  S3 ^= S21; S12 ^= S21;
    SMIX(S12, S13, S14, S15);
    S16 ^= S12; S22 ^= S12; S30 ^= S12;  S3 ^= S12;
    SMIX( S3,  S4,  S5,  S6);
     S7 ^=  S3; S13 ^=  S3; S22 ^=  S3; S30 ^=  S3;
    SMIX(S30, S31, S32, S33);
    S34 ^= S30;  S4 ^= S30; S13 ^= S30; S22 ^= S30;
    SMIX(S22, S23, S24, S25);
    // i = 10
    S26 ^= S22; S31 ^= S22;  S4 ^= S22; S13 ^= S22;
    SMIX(S13, S14, S15, S16);
    S17 ^= S13; S23 ^= S13; S31 ^= S13;  S4 ^= S13;
    SMIX( S4,  S5,  S6,  S7);
     S8 ^=  S4; S14 ^=  S4; S23 ^=  S4; S31 ^=  S4;
    SMIX(S31, S32, S33, S34);
    S35 ^= S31;  S5 ^= S31; S14 ^= S31; S23 ^= S31;
    SMIX(S23, S24, S25, S26);
    // i = 11
    S27 ^= S23; S32 ^= S23;  S5 ^= S23; S14 ^= S23;
    SMIX(S14, S15, S16, S17);
    S18 ^= S14; S24 ^= S14; S32 ^= S14;  S5 ^= S14;
    SMIX( S5,  S6,  S7,  S8);
     S9 ^=  S5; S15 ^=  S5; S24 ^=  S5; S32 ^=  S5;
    SMIX(S32, S33, S34, S35);
     S0 ^= S32;  S6 ^= S32; S15 ^= S32; S24 ^= S32;
    SMIX(S24, S25, S26, S27);
    // i = 12
    S28 ^= S24; S33 ^= S24;  S6 ^= S24; S15 ^= S24;
    SMIX(S15, S16, S17, S18);
    S19 ^= S15; S25 ^= S15; S33 ^= S15;  S6 ^= S15;
    SMIX( S6,  S7,  S8,  S9);
    S10 ^=  S6; S16 ^=  S6; S25 ^=  S6; S33 ^=  S6;
    SMIX(S33, S34, S35,  S0);
     S1 ^= S33;  S7 ^= S33; S16 ^= S33; S25 ^= S33;
    SMIX(S25, S26, S27, S28);

    // Copy to output
    S29 ^= S25; S34 ^= S25;  S7 ^= S25; S16 ^= S25;
    enc32be(((unsigned char *)dst) +  0, S26);
    enc32be(((unsigned char *)dst) +  4, S27);
    enc32be(((unsigned char *)dst) +  8, S28);
    enc32be(((unsigned char *)dst) + 12, S29);
    enc32be(((unsigned char *)dst) + 16, S34);
    enc32be(((unsigned char *)dst) + 20, S35);
    enc32be(((unsigned char *)dst) + 24,  S0);
    enc32be(((unsigned char *)dst) + 28,  S1);
    enc32be(((unsigned char *)dst) + 32,  S7);
    enc32be(((unsigned char *)dst) + 36,  S8);
    enc32be(((unsigned char *)dst) + 40,  S9);
    enc32be(((unsigned char *)dst) + 44, S10);
    enc32be(((unsigned char *)dst) + 48, S16);
    enc32be(((unsigned char *)dst) + 52, S17);
    enc32be(((unsigned char *)dst) + 56, S18);
    enc32be(((unsigned char *)dst) + 60, S19);
}


