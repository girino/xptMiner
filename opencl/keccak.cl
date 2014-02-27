
#define TH_ELT(t, c0, c1, c2, c3, c4, d0, d1, d2, d3, d4) \
{ \
    t = rotate((ulong)(d0 ^ d1 ^ d2 ^ d3 ^ d4), (ulong)1) \
                    ^ (c0 ^ c1 ^ c2 ^ c3 ^ c4);           \
}

#define THETA(b00, b01, b02, b03, b04, \
              b10, b11, b12, b13, b14, \
              b20, b21, b22, b23, b24, \
              b30, b31, b32, b33, b34, \
              b40, b41, b42, b43, b44) \
{ \
    TH_ELT(t0, b40, b41, b42, b43, b44, b10, b11, b12, b13, b14); \
    TH_ELT(t1, b00, b01, b02, b03, b04, b20, b21, b22, b23, b24); \
    TH_ELT(t2, b10, b11, b12, b13, b14, b30, b31, b32, b33, b34); \
    TH_ELT(t3, b20, b21, b22, b23, b24, b40, b41, b42, b43, b44); \
    TH_ELT(t4, b30, b31, b32, b33, b34, b00, b01, b02, b03, b04); \
    b00 ^= t0; b01 ^= t0; b02 ^= t0; b03 ^= t0; b04 ^= t0; \
    b10 ^= t1; b11 ^= t1; b12 ^= t1; b13 ^= t1; b14 ^= t1; \
    b20 ^= t2; b21 ^= t2; b22 ^= t2; b23 ^= t2; b24 ^= t2; \
    b30 ^= t3; b31 ^= t3; b32 ^= t3; b33 ^= t3; b34 ^= t3; \
    b40 ^= t4; b41 ^= t4; b42 ^= t4; b43 ^= t4; b44 ^= t4; \
}

#define RHO(b00, b01, b02, b03, b04, \
            b10, b11, b12, b13, b14, \
            b20, b21, b22, b23, b24, \
            b30, b31, b32, b33, b34, \
            b40, b41, b42, b43, b44) \
{ \
    b01 = rotate(b01, (ulong)36); \
    b02 = rotate(b02, (ulong) 3); \
    b03 = rotate(b03, (ulong)41); \
    b04 = rotate(b04, (ulong)18); \
    b10 = rotate(b10, (ulong) 1); \
    b11 = rotate(b11, (ulong)44); \
    b12 = rotate(b12, (ulong)10); \
    b13 = rotate(b13, (ulong)45); \
    b14 = rotate(b14, (ulong) 2); \
    b20 = rotate(b20, (ulong)62); \
    b21 = rotate(b21, (ulong) 6); \
    b22 = rotate(b22, (ulong)43); \
    b23 = rotate(b23, (ulong)15); \
    b24 = rotate(b24, (ulong)61); \
    b30 = rotate(b30, (ulong)28); \
    b31 = rotate(b31, (ulong)55); \
    b32 = rotate(b32, (ulong)25); \
    b33 = rotate(b33, (ulong)21); \
    b34 = rotate(b34, (ulong)56); \
    b40 = rotate(b40, (ulong)27); \
    b41 = rotate(b41, (ulong)20); \
    b42 = rotate(b42, (ulong)39); \
    b43 = rotate(b43, (ulong) 8); \
    b44 = rotate(b44, (ulong)14); \
}

/*
 * The KHI macro integrates the "lane complement" optimization. On input,
 * some words are complemented:
 *    a00 a01 a02 a04 a13 a20 a21 a22 a30 a33 a34 a43
 * On output, the following words are complemented:
 *    a04 a10 a20 a22 a23 a31
 *
 * The (implicit) permutation and the theta expansion will bring back
 * the input mask for the next round.
 */

#define KHI(b00, b01, b02, b03, b04, \
            b10, b11, b12, b13, b14, \
            b20, b21, b22, b23, b24, \
            b30, b31, b32, b33, b34, \
            b40, b41, b42, b43, b44) \
{ \
    t0 = b00 ^ ( b10 |  b20); \
    t1 = b10 ^ (~b20 |  b30); \
    t2 = b20 ^ ( b30 &  b40); \
    t3 = b30 ^ ( b40 |  b00); \
    t4 = b40 ^ ( b00 &  b10); \
    b00 = t0; b10 = t1; b20 = t2; b30 = t3; b40 = t4; \
    \
    t0 = b01 ^ ( b11 |  b21); \
    t1 = b11 ^ ( b21 &  b31); \
    t2 = b21 ^ ( b31 | ~b41); \
    t3 = b31 ^ ( b41 |  b01); \
    t4 = b41 ^ ( b01 &  b11); \
    b01 = t0; b11 = t1; b21 = t2; b31 = t3; b41 = t4; \
    \
    t0 = b02 ^ ( b12 |  b22); \
    t1 = b12 ^ ( b22 &  b32); \
    t2 = b22 ^ (~b32 &  b42); \
    t3 =~b32 ^ ( b42 |  b02); \
    t4 = b42 ^ ( b02 &  b12); \
    b02 = t0; b12 = t1; b22 = t2; b32 = t3; b42 = t4; \
    \
    t0 = b03 ^ ( b13 &  b23); \
    t1 = b13 ^ ( b23 |  b33); \
    t2 = b23 ^ (~b33 |  b43); \
    t3 =~b33 ^ ( b43 &  b03); \
    t4 = b43 ^ ( b03 |  b13); \
    b03 = t0; b13 = t1; b23 = t2; b33 = t3; b43 = t4; \
    \
    t0 = b04 ^ (~b14 &  b24); \
    t1 =~b14 ^ ( b24 |  b34); \
    t2 = b24 ^ ( b34 &  b44); \
    t3 = b34 ^ ( b44 |  b04); \
    t4 = b44 ^ ( b04 &  b14); \
    b04 = t0; b14 = t1; b24 = t2; b34 = t3; b44 = t4; \
}

#define IOTA(r) { a00 ^= r; }


void keccak(constant ulong *_wide, constant uint *_buf, uint nonce, ulong *dst)
{
    // Keccak init (doesn't do anything anymore)
    
    
    // Keccak core
    // DECL_STATE
    ulong a00, a01, a02, a03, a04;
    ulong a10, a11, a12, a13, a14;
    ulong a20, a21, a22, a23, a24;
    ulong a30, a31, a32, a33, a34;
    ulong a40, a41, a42, a43, a44;
    
    // READ_STATE
    a00 = _wide[ 0] ^ ( ((ulong)nonce << 32) | _buf[0] );  
    a10 = _wide[ 1] ^ 0x01;
    a20 = _wide[ 2];
    a30 = _wide[ 3];
    a40 = _wide[ 4];
    a01 = _wide[ 5];
    a11 = _wide[ 6];
    a21 = _wide[ 7];
    a31 = _wide[ 8] ^ 0x8000000000000000;
    a41 = _wide[ 9];
    a02 = _wide[10];
    a12 = _wide[11];
    a22 = _wide[12];
    a32 = _wide[13];
    a42 = _wide[14];
    a03 = _wide[15];
    a13 = _wide[16];
    a23 = _wide[17];
    a33 = _wide[18];
    a43 = _wide[19];
    a04 = _wide[20];
    a14 = _wide[21];
    a24 = _wide[22];
    a34 = _wide[23];
    a44 = _wide[24];
    
    // INPUT_BUF72 (doesn't do anything anymore)

    // Temp variables for THETA and KHI
    ulong t0, t1, t2, t3, t4;

    /*
    #pragma unroll
    for (int j = 0; j < 24; j ++) {
        THETA ( a00, a01, a02, a03, a04, a10, a11, a12, a13, a14, a20, a21, a22, a23, a24, a30, a31, a32, a33, a34, a40, a41, a42, a43, a44 );
          RHO ( a00, a01, a02, a03, a04, a10, a11, a12, a13, a14, a20, a21, a22, a23, a24, a30, a31, a32, a33, a34, a40, a41, a42, a43, a44 );
          KHI ( a00, a30, a10, a40, a20, a11, a41, a21, a01, a31, a22, a02, a32, a12, a42, a33, a13, a43, a23, a03, a44, a24, a04, a34, a14 );
        IOTA(RC[j + 0]);
        P1_TO_P0;
    }
    */

    // i = 0
    THETA ( a00, a01, a02, a03, a04, a10, a11, a12, a13, a14, a20, a21, a22, a23, a24, a30, a31, a32, a33, a34, a40, a41, a42, a43, a44 );
      RHO ( a00, a01, a02, a03, a04, a10, a11, a12, a13, a14, a20, a21, a22, a23, a24, a30, a31, a32, a33, a34, a40, a41, a42, a43, a44 );
      KHI ( a00, a30, a10, a40, a20, a11, a41, a21, a01, a31, a22, a02, a32, a12, a42, a33, a13, a43, a23, a03, a44, a24, a04, a34, a14 );
    IOTA(0x0000000000000001);

    // i = 1
    THETA ( a00, a30, a10, a40, a20, a11, a41, a21, a01, a31, a22, a02, a32, a12, a42, a33, a13, a43, a23, a03, a44, a24, a04, a34, a14 );
      RHO ( a00, a30, a10, a40, a20, a11, a41, a21, a01, a31, a22, a02, a32, a12, a42, a33, a13, a43, a23, a03, a44, a24, a04, a34, a14 );
      KHI ( a00, a33, a11, a44, a22, a41, a24, a02, a30, a13, a32, a10, a43, a21, a04, a23, a01, a34, a12, a40, a14, a42, a20, a03, a31 );
    IOTA(0x0000000000008082);

    // i = 2
    THETA ( a00, a33, a11, a44, a22, a41, a24, a02, a30, a13, a32, a10, a43, a21, a04, a23, a01, a34, a12, a40, a14, a42, a20, a03, a31 );
      RHO ( a00, a33, a11, a44, a22, a41, a24, a02, a30, a13, a32, a10, a43, a21, a04, a23, a01, a34, a12, a40, a14, a42, a20, a03, a31 );
      KHI ( a00, a23, a41, a14, a32, a24, a42, a10, a33, a01, a43, a11, a34, a02, a20, a12, a30, a03, a21, a44, a31, a04, a22, a40, a13 );
    IOTA(0x800000000000808A);

    // i = 3
    THETA ( a00, a23, a41, a14, a32, a24, a42, a10, a33, a01, a43, a11, a34, a02, a20, a12, a30, a03, a21, a44, a31, a04, a22, a40, a13 );
      RHO ( a00, a23, a41, a14, a32, a24, a42, a10, a33, a01, a43, a11, a34, a02, a20, a12, a30, a03, a21, a44, a31, a04, a22, a40, a13 );
      KHI ( a00, a12, a24, a31, a43, a42, a04, a11, a23, a30, a34, a41, a03, a10, a22, a21, a33, a40, a02, a14, a13, a20, a32, a44, a01 );
    IOTA(0x8000000080008000);

    // i = 4
    THETA ( a00, a12, a24, a31, a43, a42, a04, a11, a23, a30, a34, a41, a03, a10, a22, a21, a33, a40, a02, a14, a13, a20, a32, a44, a01 );
      RHO ( a00, a12, a24, a31, a43, a42, a04, a11, a23, a30, a34, a41, a03, a10, a22, a21, a33, a40, a02, a14, a13, a20, a32, a44, a01 );
      KHI ( a00, a21, a42, a13, a34, a04, a20, a41, a12, a33, a03, a24, a40, a11, a32, a02, a23, a44, a10, a31, a01, a22, a43, a14, a30 );
    IOTA(0x000000000000808B);

    // i = 5
    THETA ( a00, a21, a42, a13, a34, a04, a20, a41, a12, a33, a03, a24, a40, a11, a32, a02, a23, a44, a10, a31, a01, a22, a43, a14, a30 );
      RHO ( a00, a21, a42, a13, a34, a04, a20, a41, a12, a33, a03, a24, a40, a11, a32, a02, a23, a44, a10, a31, a01, a22, a43, a14, a30 );
      KHI ( a00, a02, a04, a01, a03, a20, a22, a24, a21, a23, a40, a42, a44, a41, a43, a10, a12, a14, a11, a13, a30, a32, a34, a31, a33 );
    IOTA(0x0000000080000001);

    // i = 6
    THETA ( a00, a02, a04, a01, a03, a20, a22, a24, a21, a23, a40, a42, a44, a41, a43, a10, a12, a14, a11, a13, a30, a32, a34, a31, a33 );
      RHO ( a00, a02, a04, a01, a03, a20, a22, a24, a21, a23, a40, a42, a44, a41, a43, a10, a12, a14, a11, a13, a30, a32, a34, a31, a33 );
      KHI ( a00, a10, a20, a30, a40, a22, a32, a42, a02, a12, a44, a04, a14, a24, a34, a11, a21, a31, a41, a01, a33, a43, a03, a13, a23 );
    IOTA(0x8000000080008081);

    // i = 7
    THETA ( a00, a10, a20, a30, a40, a22, a32, a42, a02, a12, a44, a04, a14, a24, a34, a11, a21, a31, a41, a01, a33, a43, a03, a13, a23 );
      RHO ( a00, a10, a20, a30, a40, a22, a32, a42, a02, a12, a44, a04, a14, a24, a34, a11, a21, a31, a41, a01, a33, a43, a03, a13, a23 );
      KHI ( a00, a11, a22, a33, a44, a32, a43, a04, a10, a21, a14, a20, a31, a42, a03, a41, a02, a13, a24, a30, a23, a34, a40, a01, a12 );
    IOTA(0x8000000000008009);

    // i = 8
    THETA ( a00, a11, a22, a33, a44, a32, a43, a04, a10, a21, a14, a20, a31, a42, a03, a41, a02, a13, a24, a30, a23, a34, a40, a01, a12 );
      RHO ( a00, a11, a22, a33, a44, a32, a43, a04, a10, a21, a14, a20, a31, a42, a03, a41, a02, a13, a24, a30, a23, a34, a40, a01, a12 );
      KHI ( a00, a41, a32, a23, a14, a43, a34, a20, a11, a02, a31, a22, a13, a04, a40, a24, a10, a01, a42, a33, a12, a03, a44, a30, a21 );
    IOTA(0x000000000000008A);

    // i = 9
    THETA ( a00, a41, a32, a23, a14, a43, a34, a20, a11, a02, a31, a22, a13, a04, a40, a24, a10, a01, a42, a33, a12, a03, a44, a30, a21 );
      RHO ( a00, a41, a32, a23, a14, a43, a34, a20, a11, a02, a31, a22, a13, a04, a40, a24, a10, a01, a42, a33, a12, a03, a44, a30, a21 );
      KHI ( a00, a24, a43, a12, a31, a34, a03, a22, a41, a10, a13, a32, a01, a20, a44, a42, a11, a30, a04, a23, a21, a40, a14, a33, a02 );
    IOTA(0x0000000000000088);

    // i = 10
    THETA ( a00, a24, a43, a12, a31, a34, a03, a22, a41, a10, a13, a32, a01, a20, a44, a42, a11, a30, a04, a23, a21, a40, a14, a33, a02 );
      RHO ( a00, a24, a43, a12, a31, a34, a03, a22, a41, a10, a13, a32, a01, a20, a44, a42, a11, a30, a04, a23, a21, a40, a14, a33, a02 );
      KHI ( a00, a42, a34, a21, a13, a03, a40, a32, a24, a11, a01, a43, a30, a22, a14, a04, a41, a33, a20, a12, a02, a44, a31, a23, a10 );
    IOTA(0x0000000080008009);

    // i = 11
    THETA ( a00, a42, a34, a21, a13, a03, a40, a32, a24, a11, a01, a43, a30, a22, a14, a04, a41, a33, a20, a12, a02, a44, a31, a23, a10 );
      RHO ( a00, a42, a34, a21, a13, a03, a40, a32, a24, a11, a01, a43, a30, a22, a14, a04, a41, a33, a20, a12, a02, a44, a31, a23, a10 );
      KHI ( a00, a04, a03, a02, a01, a40, a44, a43, a42, a41, a30, a34, a33, a32, a31, a20, a24, a23, a22, a21, a10, a14, a13, a12, a11 );
    IOTA(0x000000008000000A);

    // i = 12
    THETA ( a00, a04, a03, a02, a01, a40, a44, a43, a42, a41, a30, a34, a33, a32, a31, a20, a24, a23, a22, a21, a10, a14, a13, a12, a11 );
      RHO ( a00, a04, a03, a02, a01, a40, a44, a43, a42, a41, a30, a34, a33, a32, a31, a20, a24, a23, a22, a21, a10, a14, a13, a12, a11 );
      KHI ( a00, a20, a40, a10, a30, a44, a14, a34, a04, a24, a33, a03, a23, a43, a13, a22, a42, a12, a32, a02, a11, a31, a01, a21, a41 );
    IOTA(0x000000008000808B);

    // i = 13
    THETA ( a00, a20, a40, a10, a30, a44, a14, a34, a04, a24, a33, a03, a23, a43, a13, a22, a42, a12, a32, a02, a11, a31, a01, a21, a41 );
      RHO ( a00, a20, a40, a10, a30, a44, a14, a34, a04, a24, a33, a03, a23, a43, a13, a22, a42, a12, a32, a02, a11, a31, a01, a21, a41 );
      KHI ( a00, a22, a44, a11, a33, a14, a31, a03, a20, a42, a23, a40, a12, a34, a01, a32, a04, a21, a43, a10, a41, a13, a30, a02, a24 );
    IOTA(0x800000000000008B);

    // i = 14
    THETA ( a00, a22, a44, a11, a33, a14, a31, a03, a20, a42, a23, a40, a12, a34, a01, a32, a04, a21, a43, a10, a41, a13, a30, a02, a24 );
      RHO ( a00, a22, a44, a11, a33, a14, a31, a03, a20, a42, a23, a40, a12, a34, a01, a32, a04, a21, a43, a10, a41, a13, a30, a02, a24 );
      KHI ( a00, a32, a14, a41, a23, a31, a13, a40, a22, a04, a12, a44, a21, a03, a30, a43, a20, a02, a34, a11, a24, a01, a33, a10, a42 );
    IOTA(0x8000000000008089);

    // i = 15
    THETA ( a00, a32, a14, a41, a23, a31, a13, a40, a22, a04, a12, a44, a21, a03, a30, a43, a20, a02, a34, a11, a24, a01, a33, a10, a42 );
      RHO ( a00, a32, a14, a41, a23, a31, a13, a40, a22, a04, a12, a44, a21, a03, a30, a43, a20, a02, a34, a11, a24, a01, a33, a10, a42 );
      KHI ( a00, a43, a31, a24, a12, a13, a01, a44, a32, a20, a21, a14, a02, a40, a33, a34, a22, a10, a03, a41, a42, a30, a23, a11, a04 );
    IOTA(0x8000000000008003);

    // i = 16
    THETA ( a00, a43, a31, a24, a12, a13, a01, a44, a32, a20, a21, a14, a02, a40, a33, a34, a22, a10, a03, a41, a42, a30, a23, a11, a04 );
      RHO ( a00, a43, a31, a24, a12, a13, a01, a44, a32, a20, a21, a14, a02, a40, a33, a34, a22, a10, a03, a41, a42, a30, a23, a11, a04 );
      KHI ( a00, a34, a13, a42, a21, a01, a30, a14, a43, a22, a02, a31, a10, a44, a23, a03, a32, a11, a40, a24, a04, a33, a12, a41, a20 );
    IOTA(0x8000000000008002);

    // i = 17
    THETA ( a00, a34, a13, a42, a21, a01, a30, a14, a43, a22, a02, a31, a10, a44, a23, a03, a32, a11, a40, a24, a04, a33, a12, a41, a20 );
      RHO ( a00, a34, a13, a42, a21, a01, a30, a14, a43, a22, a02, a31, a10, a44, a23, a03, a32, a11, a40, a24, a04, a33, a12, a41, a20 );
      KHI ( a00, a03, a01, a04, a02, a30, a33, a31, a34, a32, a10, a13, a11, a14, a12, a40, a43, a41, a44, a42, a20, a23, a21, a24, a22 );
    IOTA(0x8000000000000080);

    // i = 18
    THETA ( a00, a03, a01, a04, a02, a30, a33, a31, a34, a32, a10, a13, a11, a14, a12, a40, a43, a41, a44, a42, a20, a23, a21, a24, a22 );
      RHO ( a00, a03, a01, a04, a02, a30, a33, a31, a34, a32, a10, a13, a11, a14, a12, a40, a43, a41, a44, a42, a20, a23, a21, a24, a22 );
      KHI ( a00, a40, a30, a20, a10, a33, a23, a13, a03, a43, a11, a01, a41, a31, a21, a44, a34, a24, a14, a04, a22, a12, a02, a42, a32 );
    IOTA(0x000000000000800A);

    // i = 19
    THETA ( a00, a40, a30, a20, a10, a33, a23, a13, a03, a43, a11, a01, a41, a31, a21, a44, a34, a24, a14, a04, a22, a12, a02, a42, a32 );
      RHO ( a00, a40, a30, a20, a10, a33, a23, a13, a03, a43, a11, a01, a41, a31, a21, a44, a34, a24, a14, a04, a22, a12, a02, a42, a32 );
      KHI ( a00, a44, a33, a22, a11, a23, a12, a01, a40, a34, a41, a30, a24, a13, a02, a14, a03, a42, a31, a20, a32, a21, a10, a04, a43 );
    IOTA(0x800000008000000A);

    // i = 20
    THETA ( a00, a44, a33, a22, a11, a23, a12, a01, a40, a34, a41, a30, a24, a13, a02, a14, a03, a42, a31, a20, a32, a21, a10, a04, a43 );
      RHO ( a00, a44, a33, a22, a11, a23, a12, a01, a40, a34, a41, a30, a24, a13, a02, a14, a03, a42, a31, a20, a32, a21, a10, a04, a43 );
      KHI ( a00, a14, a23, a32, a41, a12, a21, a30, a44, a03, a24, a33, a42, a01, a10, a31, a40, a04, a13, a22, a43, a02, a11, a20, a34 );
    IOTA(0x8000000080008081);

    // i = 21
    THETA ( a00, a14, a23, a32, a41, a12, a21, a30, a44, a03, a24, a33, a42, a01, a10, a31, a40, a04, a13, a22, a43, a02, a11, a20, a34 );
      RHO ( a00, a14, a23, a32, a41, a12, a21, a30, a44, a03, a24, a33, a42, a01, a10, a31, a40, a04, a13, a22, a43, a02, a11, a20, a34 );
      KHI ( a00, a31, a12, a43, a24, a21, a02, a33, a14, a40, a42, a23, a04, a30, a11, a13, a44, a20, a01, a32, a34, a10, a41, a22, a03 );
    IOTA(0x8000000000008080);

    // i = 22
    THETA ( a00, a31, a12, a43, a24, a21, a02, a33, a14, a40, a42, a23, a04, a30, a11, a13, a44, a20, a01, a32, a34, a10, a41, a22, a03 );
      RHO ( a00, a31, a12, a43, a24, a21, a02, a33, a14, a40, a42, a23, a04, a30, a11, a13, a44, a20, a01, a32, a34, a10, a41, a22, a03 );
      KHI ( a00, a13, a21, a34, a42, a02, a10, a23, a31, a44, a04, a12, a20, a33, a41, a01, a14, a22, a30, a43, a03, a11, a24, a32, a40 );
    IOTA(0x0000000080000001);

    // i = 23
    THETA ( a00, a13, a21, a34, a42, a02, a10, a23, a31, a44, a04, a12, a20, a33, a41, a01, a14, a22, a30, a43, a03, a11, a24, a32, a40 );
      RHO ( a00, a13, a21, a34, a42, a02, a10, a23, a31, a44, a04, a12, a20, a33, a41, a01, a14, a22, a30, a43, a03, a11, a24, a32, a40 );
      KHI ( a00, a01, a02, a03, a04, a10, a11, a12, a13, a14, a20, a21, a22, a23, a24, a30, a31, a32, a33, a34, a40, a41, a42, a43, a44 );
    IOTA(0x8000000080008008);

    
    // WRITE_STATE
    dst[0] =  a00;
    dst[1] = ~a10;
    dst[2] = ~a20;
    dst[3] =  a30;
    dst[4] =  a40;
    dst[5] =  a01;
    dst[6] =  a11;
    dst[7] =  a21;
}
