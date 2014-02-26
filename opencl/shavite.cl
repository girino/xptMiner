
#define AES_ROUND_LE(X, Y)   { \
        Y.s0  = local_AES0[UINT_BYTE3(X.s0)]; \
        Y.s1  = local_AES1[UINT_BYTE2(X.s2)]; \
        Y.s2  = local_AES2[UINT_BYTE1(X.s0)]; \
        Y.s3  = local_AES3[UINT_BYTE0(X.s2)]; \
        \
        Y.s0 ^= local_AES1[UINT_BYTE2(X.s1)]; \
        Y.s1 ^= local_AES2[UINT_BYTE1(X.s3)]; \
        Y.s2 ^= local_AES3[UINT_BYTE0(X.s1)]; \
        Y.s3 ^= local_AES0[UINT_BYTE3(X.s3)]; \
        \
        Y.s0 ^= local_AES2[UINT_BYTE1(X.s2)]; \
        Y.s1 ^= local_AES3[UINT_BYTE0(X.s0)]; \
        Y.s2 ^= local_AES0[UINT_BYTE3(X.s2)]; \
        Y.s3 ^= local_AES1[UINT_BYTE2(X.s0)]; \
        \
        Y.s0 ^= local_AES3[UINT_BYTE0(X.s3)]; \
        Y.s1 ^= local_AES0[UINT_BYTE3(X.s1)]; \
        Y.s2 ^= local_AES1[UINT_BYTE2(X.s3)]; \
        Y.s3 ^= local_AES2[UINT_BYTE1(X.s1)]; \
    }

#define AES_ROUND_NOKEY(x)   { \
        uint4 t = x; \
        AES_ROUND_LE(t, x); \
    }

#define KEY_EXPAND_ELT(k)   { \
        AES_ROUND_NOKEY(k); \
        k = k.s1230; \
    }


void
shavite(uint* restrict in_out,
        local uint* restrict local_AES0,
        local uint* restrict local_AES1,
        local uint* restrict local_AES2,
        local uint* restrict local_AES3
        )
{
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

    p0_3 = MAKE_UINT4(0x72FCCDD8, 0x79CA4727, 0x128A077B, 0x40D55AEC);
    p4_7 = MAKE_UINT4(0xD1901A06, 0x430AE307, 0xB29F5CD1, 0xDF07FBFC);
    p8_B = MAKE_UINT4(0x8E45D73D, 0x681AB538, 0xBDE86578, 0xDD577E47);
    pC_F = MAKE_UINT4(0xE275EADE, 0x502D9FCD, 0xB9357178, 0x022A4B9A);

    rk00_03 = MAKE_UINT4(in_out[0x0], in_out[0x1], in_out[0x2], in_out[0x3]);
    rk04_07 = MAKE_UINT4(in_out[0x4], in_out[0x5], in_out[0x6], in_out[0x7]);
    rk08_0B = MAKE_UINT4(in_out[0x8], in_out[0x9], in_out[0xA], in_out[0xB]);
    rk0C_0F = MAKE_UINT4(in_out[0xC], in_out[0xD], in_out[0xE], in_out[0xF]);
    rk10_13 = MAKE_UINT4( 0x00000080,           0,           0,           0);
    rk14_17 = MAKE_UINT4(          0,           0,           0,           0);
    rk18_1B = MAKE_UINT4(          0,           0,           0,  0x02000000);
    rk1C_1F = MAKE_UINT4(          0,           0,           0,  0x02000000);
    
    x = p4_7 ^ rk00_03;
    AES_ROUND_NOKEY(x);
    
    x ^= rk04_07;
    AES_ROUND_NOKEY(x);
    
    x ^= rk08_0B;
    AES_ROUND_NOKEY(x);
    
    x ^= rk0C_0F;
    AES_ROUND_NOKEY(x);
    
    p0_3 ^= x;
    x = pC_F ^ rk10_13;
    AES_ROUND_NOKEY(x);
    
    // x ^= rk14_17;  (ALL ZEROES)
    AES_ROUND_NOKEY(x);
    
    x ^= rk18_1B;
    AES_ROUND_NOKEY(x);
    
    x ^= rk1C_1F;
    AES_ROUND_NOKEY(x);
    
    p8_B ^= x;

#pragma unroll
    for (int r = 0; r < 3; r ++) {
        /* round 1, 5, 9 */
        KEY_EXPAND_ELT(rk00_03);
        rk00_03 ^= rk1C_1F;
        if (r == 0) {
            rk00_03 ^= MAKE_UINT4(0x0200, 0, 0, 0xFFFFFFFF);
        }
        x = p0_3 ^ rk00_03;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk04_07);
        rk04_07 ^= rk00_03;
        if (r == 1) {
            rk04_07 ^= MAKE_UINT4(0, 0, 0, 0xFFFFFDFF);
        }
        x ^= rk04_07;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk08_0B);
        rk08_0B ^= rk04_07;
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk0C_0F);
        rk0C_0F ^= rk08_0B;
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x);
        
        pC_F ^= x;
        
        KEY_EXPAND_ELT(rk10_13);
        rk10_13 ^= rk0C_0F;
        x = p8_B ^ rk10_13;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk14_17);
        rk14_17 ^= rk10_13;
        x ^= rk14_17;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk18_1B);
        rk18_1B ^= rk14_17;
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk1C_1F);
        rk1C_1F ^= rk18_1B;
        if (r == 2) {
            rk1C_1F ^= MAKE_UINT4(0, 0, 0x0200, 0xFFFFFFFF);
        }
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x);
        
        p4_7 ^= x;
        
        /* round 2, 6, 10 */
        rk00_03 ^= MAKE_UINT4(rk18_1B.s1, rk18_1B.s2, rk18_1B.s3, rk1C_1F.s0);
        x = pC_F ^ rk00_03;
        AES_ROUND_NOKEY(x);
        
        rk04_07 ^= MAKE_UINT4(rk1C_1F.s1, rk1C_1F.s2, rk1C_1F.s3, rk00_03.s0);
        x ^= rk04_07;
        AES_ROUND_NOKEY(x);
        
        rk08_0B ^= MAKE_UINT4(rk00_03.s1, rk00_03.s2, rk00_03.s3, rk04_07.s0);
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x);
        
        rk0C_0F ^= MAKE_UINT4(rk04_07.s1, rk04_07.s2, rk04_07.s3, rk08_0B.s0);
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x);
        
        p8_B ^= x;
        
        rk10_13 ^= MAKE_UINT4(rk08_0B.s1, rk08_0B.s2, rk08_0B.s3, rk0C_0F.s0);
        x = p4_7 ^ rk10_13;
        AES_ROUND_NOKEY(x);
        
        rk14_17 ^= MAKE_UINT4(rk0C_0F.s1, rk0C_0F.s2, rk0C_0F.s3, rk10_13.s0);
        x ^= rk14_17;
        AES_ROUND_NOKEY(x);
        
        rk18_1B ^= MAKE_UINT4(rk10_13.s1, rk10_13.s2, rk10_13.s3, rk14_17.s0);
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x);
        
        rk1C_1F ^= MAKE_UINT4(rk14_17.s1, rk14_17.s2, rk14_17.s3, rk18_1B.s0);
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x);
        
        p0_3 ^= x;
        
        /* round 3, 7, 11 */
        KEY_EXPAND_ELT(rk00_03);
        rk00_03 ^= rk1C_1F;
        x = p8_B ^ rk00_03;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk04_07);
        rk04_07 ^= rk00_03;
        x ^= rk04_07;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk08_0B);
        rk08_0B ^= rk04_07;
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk0C_0F);
        rk0C_0F ^= rk08_0B;
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x);
        
        p4_7 ^= x;
        
        KEY_EXPAND_ELT(rk10_13);
        rk10_13 ^= rk0C_0F;
        x = p0_3 ^ rk10_13;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk14_17);
        rk14_17 ^= rk10_13;
        x ^= rk14_17;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk18_1B);
        rk18_1B ^= rk14_17;
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x);
        
        KEY_EXPAND_ELT(rk1C_1F);
        rk1C_1F ^= rk18_1B;
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x);
        
        pC_F ^= x;
        
        /* round 4, 8, 12 */
        rk00_03 ^= MAKE_UINT4(rk18_1B.s1, rk18_1B.s2, rk18_1B.s3, rk1C_1F.s0);
        x = p4_7 ^ rk00_03;
        AES_ROUND_NOKEY(x);
        
        rk04_07 ^= MAKE_UINT4(rk1C_1F.s1, rk1C_1F.s2, rk1C_1F.s3, rk00_03.s0);
        x ^= rk04_07;
        AES_ROUND_NOKEY(x);
        
        rk08_0B ^= MAKE_UINT4(rk00_03.s1, rk00_03.s2, rk00_03.s3, rk04_07.s0);
        x ^= rk08_0B;
        AES_ROUND_NOKEY(x);
        
        rk0C_0F ^= MAKE_UINT4(rk04_07.s1, rk04_07.s2, rk04_07.s3, rk08_0B.s0);
        x ^= rk0C_0F;
        AES_ROUND_NOKEY(x);
        
        p0_3 ^= x;
        
        rk10_13 ^= MAKE_UINT4(rk08_0B.s1, rk08_0B.s2, rk08_0B.s3, rk0C_0F.s0);
        x = pC_F ^ rk10_13;
        AES_ROUND_NOKEY(x);
        
        rk14_17 ^= MAKE_UINT4(rk0C_0F.s1, rk0C_0F.s2, rk0C_0F.s3, rk10_13.s0);
        x ^= rk14_17;
        AES_ROUND_NOKEY(x);
        
        rk18_1B ^= MAKE_UINT4(rk10_13.s1, rk10_13.s2, rk10_13.s3, rk14_17.s0);
        x ^= rk18_1B;
        AES_ROUND_NOKEY(x);
        
        rk1C_1F ^= MAKE_UINT4(rk14_17.s1, rk14_17.s2, rk14_17.s3, rk18_1B.s0);
        x ^= rk1C_1F;
        AES_ROUND_NOKEY(x);
        
        p8_B ^= x;
    }
    /* round 13 */
    KEY_EXPAND_ELT(rk00_03);
    rk00_03 ^= rk1C_1F;
    x = p0_3 ^ rk00_03;
    AES_ROUND_NOKEY(x);
    
    KEY_EXPAND_ELT(rk04_07);
    rk04_07 ^= rk00_03;
    x ^= rk04_07;
    AES_ROUND_NOKEY(x);
    
    KEY_EXPAND_ELT(rk08_0B);
    rk08_0B ^= rk04_07;
    x ^= rk08_0B;
    AES_ROUND_NOKEY(x);
    
    KEY_EXPAND_ELT(rk0C_0F);
    rk0C_0F ^= rk08_0B;
    x ^= rk0C_0F;
    AES_ROUND_NOKEY(x);
    
    pC_F ^= x;
    
    KEY_EXPAND_ELT(rk10_13);
    rk10_13 ^= rk0C_0F;
    x = p8_B ^ rk10_13;
    AES_ROUND_NOKEY(x);
    
    KEY_EXPAND_ELT(rk14_17);
    rk14_17 ^= rk10_13;
    x ^= rk14_17;
    AES_ROUND_NOKEY(x);
    
    KEY_EXPAND_ELT(rk18_1B);
    rk18_1B ^= rk14_17 ^ MAKE_UINT4(0, 0x0200, 0, 0xFFFFFFFF);
    x ^= rk18_1B;
    AES_ROUND_NOKEY(x);
    
    KEY_EXPAND_ELT(rk1C_1F);
    rk1C_1F ^= rk18_1B;
    x ^= rk1C_1F;
    AES_ROUND_NOKEY(x);
    
    p4_7 ^= x;
    

    in_out[0x0] = (p8_B.s0 ^ 0x72FCCDD8);
    in_out[0x1] = (p8_B.s1 ^ 0x79CA4727);
    in_out[0x2] = (p8_B.s2 ^ 0x128A077B);
    in_out[0x3] = (p8_B.s3 ^ 0x40D55AEC);
    in_out[0x4] = (pC_F.s0 ^ 0xD1901A06);
    in_out[0x5] = (pC_F.s1 ^ 0x430AE307);
    in_out[0x6] = (pC_F.s2 ^ 0xB29F5CD1);
    in_out[0x7] = (pC_F.s3 ^ 0xDF07FBFC);
    in_out[0x8] = (p0_3.s0 ^ 0x8E45D73D);
    in_out[0x9] = (p0_3.s1 ^ 0x681AB538);
    in_out[0xA] = (p0_3.s2 ^ 0xBDE86578);
    in_out[0xB] = (p0_3.s3 ^ 0xDD577E47);
    in_out[0xC] = (p4_7.s0 ^ 0xE275EADE);
    in_out[0xD] = (p4_7.s1 ^ 0x502D9FCD);
    in_out[0xE] = (p4_7.s2 ^ 0xB9357178);
    in_out[0xF] = (p4_7.s3 ^ 0x022A4B9A);
}
