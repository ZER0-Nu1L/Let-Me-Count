#include <bitset>
#include <iostream>
#include <limits>
#include <cstdlib>
#include "./uint128_t/uint128_t.h"

#define _TEST
#define DEBRUIJN32 0
#define _DEBUG_32 0
#define DEBRUIJN64 1
#define _DEBUG_64 1

using namespace std;

// x & -x leaves only the right-most bit set in the word. Let k be the
// index of that bit. Since only a single bit is set, the value is two
// to the power of k. Multiplying by a power of two is equivalent to
// left shifting, in this case by k bits.  The de Bruijn constant is
// such that all six bit, consecutive substrings are distinct.
// Therefore, if we have a left shifted version of this constant we can
// find by how many bits it was shifted by looking at which six bit
// substring ended up at the top of the word.
int trailingZeroBits(uint32_t x) {
    const uint32_t deBruijn32 = 0x077CB531U; // a 32bit De Bruijn sequence
    static const int MultiplyDeBruijn32BitPosition[32] = {
        0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
        31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
    };
    return  MultiplyDeBruijn32BitPosition[((uint64_t)(x & -x) * (uint64_t)deBruijn32) >> 27];
}

int trailingZeroBits(uint64_t x) {
    const uint64_t deBruijn64 = 0x03f79d71b4ca8b09; // a 64bit De Bruijn sequence
    static const int MultiplyDeBruijn64BitPosition[64] = {
        0, 1, 56, 2, 57, 49, 28, 3, 61, 58, 42, 50, 38, 29, 17, 4,
        62, 47, 59, 36, 45, 43, 51, 22, 53, 39, 33, 30, 24, 18, 12, 5,
        63, 55, 48, 27, 60, 41, 37, 16, 46, 35, 44, 21, 52, 32, 23, 11,
        54, 26, 40, 15, 34, 20, 31, 10, 25, 14, 19, 9, 13, 8, 7, 6,
    };
    return  MultiplyDeBruijn64BitPosition[(uint32_t)( ((uint128_t)(x & -x) * (uint128_t)deBruijn64) >> 58)];
}
// n bit
// h(x) = (x * deBruijn_n) >> (n - lg n)


int main(int argc, char *argv[])
{
    int res;
    if(argc != 2) {
        printf("Not enough paremeter!\n");
        exit(EXIT_FAILURE);
    }

#if DEBRUIJN32
    // if v is 32bit
    uint32_t v = (uint32_t)atoi(argv[1]);
    res = trailingZeroBits(v);
    cout << res << endl;
#elif DEBRUIJN64
    // if v is 64bit
    uint64_t v = (uint64_t)atoi(argv[1]);
    res = trailingZeroBits(v);
    cout << res << endl;

#endif

#ifdef _TEST
    v = 2*2*2*2*2*2*2*2*2*2*2*2*2*2*2*2*2*2*2*2;
    v = 4*4*4*4*4*4*4*4*4*4*4*4*4*4*4;
    v = 12862352;
    v = 1024;
#endif

#if _DEBUG_32
    cout << v << endl;
    cout << bitset<32>(v) << endl;
    cout << bitset<32>(-v) << endl;
    cout << bitset<32>(v & -v) << endl;
    cout << (((v & -v) * 0x077CB531U) >> 27) << endl;
    res = trailingZeroBits(v);
    cout << res << endl;
#elif _DEBUG_64
    cout << v << endl;
    cout << bitset<64>(v) << endl;
    cout << bitset<64>(-v) << endl;
    cout << bitset<64>(v & -v) << endl;
    cout << (((v & -v) * 0x03f79d71b4ca8b09) >> 58) << endl;
    res = trailingZeroBits(v);
    cout << res << endl;
#endif

    return 0;
}