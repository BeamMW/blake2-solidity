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

    function siphash24(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 nonce)
        internal
        pure
        returns (uint64)
    {
        state3 ^= nonce;

        (state0, state1, state2, state3) = sipRound(state0, state1, state2, state3);
        (state0, state1, state2, state3) = sipRound(state0, state1, state2, state3);
        state0 ^= nonce;
        state2 ^= 0xff;
        (state0, state1, state2, state3) = sipRound(state0, state1, state2, state3);
        (state0, state1, state2, state3) = sipRound(state0, state1, state2, state3);
        (state0, state1, state2, state3) = sipRound(state0, state1, state2, state3);
        (state0, state1, state2, state3) = sipRound(state0, state1, state2, state3);

        return state0 ^ state1 ^ state2 ^ state3;
    }
}