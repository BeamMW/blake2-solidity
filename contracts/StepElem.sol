// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {SipHash} from "./SipHash.sol";

library StepElem {
    struct Instance {
        uint64[7] workWords;
    }

    uint32 constant kColisionBitSize = 24;
    uint32 constant kWorkBitSize = 448;
    uint32 constant kWordSize = 8;
    uint32 constant kColisionBytes = 3;

    function init(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 index)
        internal
        pure
        returns (Instance memory result)
    {
        uint8 i = 7;
        do {
            i--;
            result.workWords[i] = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + i);
        } while(i > 0);
    }

    function toUint64(bytes memory buffer, uint256 start)
        internal
        pure
        returns (uint64)
    {
        uint64 v = 0;
        start += 8;
        assembly {
            v := mload(add(buffer, start))
        }

        // reverse uint64:
        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);

        return v;
    }

    function mergeWith(Instance memory self, Instance memory other, uint remLen)
        internal
        pure
    {
        for (uint i = 0; i < 7; i++) {
            self.workWords[i] ^= other.workWords[i];
        }

        uint remBytes = remLen / 8;
        bytes memory buffer = new bytes(7 * 8);

        // copy to buffer
        bytes8 value = 0;
        for (uint i = 0; i < 7; i++) {
            value = bytes8(self.workWords[i]);

            // revert bytes
            for (uint j = 0; j < 8; j++) {
                buffer[i * 8 + 7 - j] = value[j];
            }
        }

        // shift to left
        for (uint i = 0; i < remBytes; i++) {
            buffer[i] = buffer[i + kColisionBytes];
        }

        for (uint i = remBytes; i < buffer.length; i++) {
            buffer[i] = 0;
        }

        // copy from buffer
        for (uint i = 0; i < 7; i++) {
            self.workWords[i] = toUint64(buffer, i * 8);
        }
    }

    function applyMix(Instance memory self, uint remLen, uint32[32] memory indices, uint startIndex, uint step)
        internal
        pure
    {
        uint64[9] memory temp;
     
        for (uint i = 0; i < self.workWords.length; i++)
            temp[i] = self.workWords[i];

        // Add in the bits of the index tree to the end of work bits
        uint padNum = ((512 - remLen) + kColisionBitSize) / (kColisionBitSize + 1);

        if (padNum > step)
            padNum = step;

        uint shift = 0;
        uint n0 = 0;
        uint64 idx = 0;
        for (uint i = 0; i < padNum; i++) {
            shift = remLen + i * (kColisionBitSize + 1);
            n0 = shift / (kWordSize * 8);
            shift %= (kWordSize * 8);

            idx = indices[startIndex + i];

            temp[n0] |= idx << uint64(shift);

            if (shift + kColisionBitSize + 1 > kWordSize * 8)
                temp[n0 + 1] |= idx >> (kWordSize * 8 - shift);
        }

        // Applyin the mix from the lined up bits
        uint64 result = 0;
        for (uint32 i = 0; i < 8; i++)
            result += SipHash.rotl(temp[i], (29 * (i + 1)) & 0x3F);

        result = SipHash.rotl(result, 24);

        // Wipe out lowest 64 bits in favor of the mixed bits
        self.workWords[0] = result;
    }

    function hasColision(Instance memory self, Instance memory other)
        internal
        pure
        returns (bool)
    {
        uint64 val = self.workWords[0] ^ other.workWords[0];
        uint64 mask = (1 << 24) - 1;

        return (val & mask) == 0;
    }
}