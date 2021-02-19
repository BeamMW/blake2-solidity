// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

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

    function mergeWith(Instance memory self, Instance memory other, uint32 remLen)
        internal
        pure
    {
        for (uint8 i = 0; i < 7; i++) {
            self.workWords[i] ^= other.workWords[i];
        }

        uint32 remBytes = remLen / 8;
        bytes memory buffer = new bytes(7 * 8);

        // copy to buffer
        for (uint16 i = 0; i < 7; i++) {
            bytes8 value = bytes8(self.workWords[i]);

            for (uint16 j = 0; j < 8; j++) {
                buffer[i * 8 + j] = value[j];
            }
        }

        // shift to left
        for (uint16 i = 0; i < remBytes; i++) {
            buffer[i] = buffer[i + kColisionBytes];
        }

        for (uint32 i = remBytes; i < buffer.length; i++) {
            buffer[i] = 0;
        }

        // copy from buffer
        for (uint16 i = 0; i < 7; i++) {
            uint32 start = i * 8;
            uint64 parsed;
            assembly {
                parsed:= mload(add(buffer, add(8, start)))
            }
            self.workWords[i] = parsed;
        }
    }

    function applyMix(Instance memory self, uint32 remLen, uint32[32] memory indices, uint32 startIndex, uint32 step)
        internal
        pure
    {
        uint64[9] memory temp;

        // TODO check this code. maybe it is odd
        for (uint8 i = 0; i < temp.length; i++)
            temp[i] = 0;
        
        for (uint8 i = 0; i < self.workWords.length; i++)
            temp[i] = self.workWords[i];

        // Add in the bits of the index tree to the end of work bits
        uint32 padNum = ((512 - remLen) + kColisionBitSize) / (kColisionBitSize + 1);

        if (padNum > step)
            padNum = step;

        for (uint32 i = 0; i < padNum; i++) {
            uint32 shift = remLen + i * (kColisionBitSize + 1);
            uint32 n0 = shift / (kWordSize * 8);
            shift %= (kWordSize * 8);

            uint64 idx = indices[startIndex + i];

            temp[n0] |= idx << shift;

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