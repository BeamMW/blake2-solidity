// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library SipHash {
    function rotl(uint x, uint b)
        internal
        pure
        returns (uint64)
    {
        return uint64((x << b)) | uint64(x >> (64 - b));
    }

    function sipRound(uint64 v0, uint64 v1, uint64 v2, uint64 v3)
        private
        pure
        returns (uint64, uint64, uint64, uint64)
    {
        v0 += v1;
        v2 += v3;
        v1 = rotl(v1, 13);
        v3 = rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = rotl(v1, 17);
        v3 = rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = rotl(v2, 32);

        return (v0, v1, v2, v3);
    }

    function siphash24(uint64 v0, uint64 v1, uint64 v2, uint64 v3, uint64 nonce)
        internal
        pure
        returns (uint64)
    {
        v3 ^= nonce;

        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);

        v0 ^= nonce;
        v2 ^= 0xff;

        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);
        // sipRound    
        v0 += v1;
        v2 += v3;
        v1 = (v1 << 13) | (v1 >> (64 - 13)); // rotl(v1, 13);
        v3 = (v3 << 16) | (v3 >> (64 - 16)); // rotl(v3, 16);
        v1 ^= v0;
        v3 ^= v2;
        v0 = (v0 << 32) | (v0 >> (64 - 32)); // rotl(v0, 32);
        v2 += v1;
        v0 += v3;
        v1 = (v1 << 17) | (v1 >> (64 - 17)); // rotl(v1, 17);
        v3 = (v3 << 21) | (v3 >> (64 - 21)); // rotl(v3, 21);
        v1 ^= v2;
        v3 ^= v0;
        v2 = (v2 << 32) | (v2 >> (64 - 32)); // rotl(v2, 32);

        return v0 ^ v1 ^ v2 ^ v3;
    }
}