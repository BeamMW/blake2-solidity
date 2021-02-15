// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

library SipHash {
    struct State {
        uint64 v0;
        uint64 v1;
        uint64 v2;
        uint64 v3;
    }

    function rotl(uint64 x, uint64 b)
        internal
        pure
        returns (uint64 ret)
    {
        ret = (x << b) | (x >> (64 - b));
    }

    function sipRound(State memory state)
        internal
        pure
    {
        state.v0 += state.v1; state.v2 += state.v3;
        state.v1 = rotl(state.v1, 13);
        state.v3 = rotl(state.v3, 16);
        state.v1 ^= state.v0; state.v3 ^= state.v2;
        state.v0 = rotl(state.v0, 32);
        state.v2 += state.v1; state.v0 += state.v3;
        state.v1 = rotl(state.v1, 17);
        state.v3 = rotl(state.v3, 21);
        state.v1 ^= state.v2; state.v3 ^= state.v0;
        state.v2 = rotl(state.v2, 32);
    }

    function siphash24(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 nonce)
        internal
        pure
        returns (uint64)
    {
        State memory state;
        state.v0 = state0;
        state.v1 = state1;
        state.v2 = state2;
        state.v3 = state3;

        state.v3 ^= nonce;

        sipRound(state);
        sipRound(state);
        state.v0 ^= nonce;
        state.v2 ^= 0xff;
        sipRound(state);
        sipRound(state);
        sipRound(state);
        sipRound(state);

        return state.v0 ^ state.v1 ^ state.v2 ^ state.v3;
    }
}