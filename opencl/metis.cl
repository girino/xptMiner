
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
    uint c0, c1, c2, c3;                 \
    uint r0, r1, r2, r3;                 \
                                         \
    r1  = local_mixtab1[UINT_BYTE1(x0)]; \
    r2  = local_mixtab2[UINT_BYTE2(x0)]; \
    r3  = local_mixtab3[UINT_BYTE3(x0)]; \
    c0  = local_mixtab0[UINT_BYTE0(x0)] ^ r1 ^ r2 ^ r3; \
    /* x0 is now free as "temp" var */   \
                                         \
    c1 = local_mixtab0[UINT_BYTE0(x1)];  \
    c2 = local_mixtab0[UINT_BYTE0(x2)];  \
    c3 = local_mixtab0[UINT_BYTE0(x3)];  \
    r0 = c1 ^ c2 ^ c3;                   \
                                         \
    c1 ^= local_mixtab1[UINT_BYTE1(x1)]; \
    x0  = local_mixtab1[UINT_BYTE1(x2)]; \
    c2 ^= x0; r1 ^= x0;                  \
    x0  = local_mixtab1[UINT_BYTE1(x3)]; \
    c3 ^= x0; r1 ^= x0;                  \
                                         \
    x0  = local_mixtab2[UINT_BYTE2(x1)]; \
    r2 ^= x0; c1 ^= x0;                  \
    c2 ^= local_mixtab2[UINT_BYTE2(x2)]; \
    x0  = local_mixtab2[UINT_BYTE2(x3)]; \
    c3 ^= x0; r2 ^= x0;                  \
                                         \
    x0  = local_mixtab3[UINT_BYTE3(x1)]; \
    c1 ^= x0; r3 ^= x0;                  \
    x0  = local_mixtab3[UINT_BYTE3(x2)]; \
    c2 ^= x0; r3 ^= x0;                  \
    c3 ^= local_mixtab3[UINT_BYTE3(x3)]; \
    \
    x0  = ((UINT_BYTE0(c0) ^ UINT_BYTE0(r0)) << 24); \
    x1  = ((UINT_BYTE0(c1) ^ UINT_BYTE1(r0)) << 24); \
    x2  = ((UINT_BYTE0(c2) ^ UINT_BYTE2(r0)) << 24); \
    x3  = ((UINT_BYTE0(c3) ^ UINT_BYTE3(r0)) << 24); \
    \
    x0 |= ((UINT_BYTE1(c1) ^ UINT_BYTE1(r1)) << 16); \
    x1 |= ((UINT_BYTE1(c2) ^ UINT_BYTE2(r1)) << 16); \
    x2 |= ((UINT_BYTE1(c3) ^ UINT_BYTE3(r1)) << 16); \
    x3 |= ((UINT_BYTE1(c0) ^ UINT_BYTE0(r1)) << 16); \
    \
    x0 |= ((UINT_BYTE2(c2) ^ UINT_BYTE2(r2)) <<  8); \
    x1 |= ((UINT_BYTE2(c3) ^ UINT_BYTE3(r2)) <<  8); \
    x2 |= ((UINT_BYTE2(c0) ^ UINT_BYTE0(r2)) <<  8); \
    x3 |= ((UINT_BYTE2(c1) ^ UINT_BYTE1(r2)) <<  8); \
    \
    x0 |= (UINT_BYTE3(c3) ^ UINT_BYTE3(r3));         \
    x1 |= (UINT_BYTE3(c0) ^ UINT_BYTE0(r3));         \
    x2 |= (UINT_BYTE3(c1) ^ UINT_BYTE1(r3));         \
    x3 |= (UINT_BYTE3(c2) ^ UINT_BYTE2(r3));         \
}


void
metis(uint *in_out,
      local uint* restrict local_mixtab0,
      local uint* restrict local_mixtab1,
      local uint* restrict local_mixtab2,
      local uint* restrict local_mixtab3)
{
    uint  S0,  S1,  S2,  S3,  S4,  S5; 
    uint  S6,  S7,  S8,  S9, S10, S11;
    uint S12, S13, S14, S15, S16, S17;
    uint S18, S19, S20, S21, S22, S23;
    uint S24, S25, S26, S27, S28, S29;
    uint S30, S31, S32, S33, S34, S35;
         
     S0 = 0x00000000;  S1 = 0x00000000;  S2 = 0x00000000;  S3 = 0x00000000;
     S4 = 0x00000000;  S5 = 0x00000000;  S6 = 0x00000000;  S7 = 0x00000000;
     S8 = 0x00000000;  S9 = 0x00000000; S10 = 0x00000000; S11 = 0x00000000;
    S12 = 0x00000000; S13 = 0x00000000; S14 = 0x00000000; S15 = 0x00000000;
    S16 = 0x00000000; S17 = 0x00000000; S18 = 0x00000000; S19 = 0x00000000;
    S20 = 0x8807A57E; S21 = 0xE616AF75; S22 = 0xC5D3E4DB; S23 = 0xAC9AB027;
    S24 = 0xD915F117; S25 = 0xB6EECC54; S26 = 0x06E8020B; S27 = 0x4A92EFD1;
    S28 = 0xAAC6E2C9; S29 = 0xDDB21398; S30 = 0xCAE65838; S31 = 0x437F203F;
    S32 = 0x25EA78E7; S33 = 0x951FDDD6; S34 = 0xDA6ED11D; S35 = 0xE13E3567;

    TIX4(SWAP32(in_out[0x00]),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(SWAP32(in_out[0x01]), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(SWAP32(in_out[0x02]), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // x
    TIX4(SWAP32(in_out[0x03]),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(SWAP32(in_out[0x04]), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(SWAP32(in_out[0x05]), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    TIX4(SWAP32(in_out[0x06]),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(SWAP32(in_out[0x07]), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(SWAP32(in_out[0x08]), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // x
    TIX4(SWAP32(in_out[0x09]),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(SWAP32(in_out[0x0A]), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(SWAP32(in_out[0x0B]), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // x
    TIX4(SWAP32(in_out[0x0C]),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
    CMIX36(S33, S34, S35,  S1,  S2,  S3, S15, S16, S17);
    SMIX(S33, S34, S35,  S0);
    CMIX36(S30, S31, S32, S34, S35,  S0, S12, S13, S14);
    SMIX(S30, S31, S32, S33);
    CMIX36(S27, S28, S29, S31, S32, S33,  S9, S10, S11);
    SMIX(S27, S28, S29, S30);
    CMIX36(S24, S25, S26, S28, S29, S30,  S6,  S7,  S8);
    SMIX(S24, S25, S26, S27);
    /* fall through */
    TIX4(SWAP32(in_out[0x0D]), S24, S25, S28, S31, S32, S10, S12, S15, S18);
    CMIX36(S21, S22, S23, S25, S26, S27,  S3,  S4,  S5);
    SMIX(S21, S22, S23, S24);
    CMIX36(S18, S19, S20, S22, S23, S24,  S0,  S1,  S2);
    SMIX(S18, S19, S20, S21);
    CMIX36(S15, S16, S17, S19, S20, S21, S33, S34, S35);
    SMIX(S15, S16, S17, S18);
    CMIX36(S12, S13, S14, S16, S17, S18, S30, S31, S32);
    SMIX(S12, S13, S14, S15);
    /* fall through */
    TIX4(SWAP32(in_out[0x0E]), S12, S13, S16, S19, S20, S34,  S0,  S3,  S6);
    CMIX36( S9, S10, S11, S13, S14, S15, S27, S28, S29);
    SMIX( S9, S10, S11, S12);
    CMIX36( S6,  S7,  S8, S10, S11, S12, S24, S25, S26);
    SMIX( S6,  S7,  S8,  S9);
    CMIX36( S3,  S4,  S5,  S7,  S8,  S9, S21, S22, S23);
    SMIX( S3,  S4,  S5,  S6);
    CMIX36( S0,  S1,  S2,  S4,  S5,  S6, S18, S19, S20);
    SMIX( S0,  S1,  S2,  S3);
    // moved from close
    TIX4(SWAP32(in_out[0x0F]),  S0,  S1,  S4,  S7,  S8, S22, S24, S27, S30);
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
    in_out[0x00] = SWAP32(S26);
    in_out[0x01] = SWAP32(S27);
    in_out[0x02] = SWAP32(S28);
    in_out[0x03] = SWAP32(S29);
    in_out[0x04] = SWAP32(S34);
    in_out[0x05] = SWAP32(S35);
    in_out[0x06] = SWAP32( S0);
    in_out[0x07] = SWAP32( S1);
    in_out[0x08] = SWAP32( S7);
    in_out[0x09] = SWAP32( S8);
    in_out[0x0A] = SWAP32( S9);
    in_out[0x0B] = SWAP32(S10);
    in_out[0x0C] = SWAP32(S16);
    in_out[0x0D] = SWAP32(S17);
    in_out[0x0E] = SWAP32(S18);
    in_out[0x0F] = SWAP32(S19);
}


