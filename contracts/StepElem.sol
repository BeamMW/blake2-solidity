// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import {SipHash} from "./SipHash.sol";
import "./BeamUtils.sol";

library StepElem {
    struct Instance {
        uint64 workWord0;
        uint64 workWord1;
        uint64 workWord2;
        uint64 workWord3;
        uint64 workWord4;
        uint64 workWord5;
        uint64 workWord6;
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
        result.workWord0 = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + 0);
        result.workWord1 = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + 1);
        result.workWord2 = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + 2);
        result.workWord3 = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + 3);
        result.workWord4 = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + 4);
        result.workWord5 = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + 5);
        result.workWord6 = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + 6);
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
        self.workWord0 ^= other.workWord0;
        self.workWord1 ^= other.workWord1;
        self.workWord2 ^= other.workWord2;
        self.workWord3 ^= other.workWord3;
        self.workWord4 ^= other.workWord4;
        self.workWord5 ^= other.workWord5;
        self.workWord6 ^= other.workWord6;

        uint remBytes = remLen / 8;
        bytes memory buffer = new bytes(7 * 8);

        // copy to buffer
        {
            // revert bytes and add to buffer
            bytes8 value = bytes8(BeamUtils.reverse64(self.workWord0));
            assembly {
                mstore(add(buffer, 32), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord1));
            assembly {
                mstore(add(buffer, 40), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord2));
            assembly {
                mstore(add(buffer, 48), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord3));
            assembly {
                mstore(add(buffer, 56), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord4));
            assembly {
                mstore(add(buffer, 64), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord5));
            assembly {
                mstore(add(buffer, 72), value)
            }
            value = bytes8(BeamUtils.reverse64(self.workWord6));
            assembly {
                mstore(add(buffer, 80), value)
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
        self.workWord0 = toUint64(buffer, 0);
        self.workWord1 = toUint64(buffer, 8);
        self.workWord2 = toUint64(buffer, 16);
        self.workWord3 = toUint64(buffer, 24);
        self.workWord4 = toUint64(buffer, 32);
        self.workWord5 = toUint64(buffer, 40);
        self.workWord6 = toUint64(buffer, 48);
    }

    function applyMix(Instance memory self, uint remLen, uint32[32] memory indices, uint startIndex, uint step)
        internal
        pure
    {
        uint64[9] memory temp;
     
        temp[0] = self.workWord0;
        temp[1] = self.workWord1;
        temp[2] = self.workWord2;
        temp[3] = self.workWord3;
        temp[4] = self.workWord4;
        temp[5] = self.workWord5;
        temp[6] = self.workWord6;

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
        result += SipHash.rotl(temp[0], (29 * 1) & 0x3F);
        result += SipHash.rotl(temp[1], (29 * 2) & 0x3F);
        result += SipHash.rotl(temp[2], (29 * 3) & 0x3F);
        result += SipHash.rotl(temp[3], (29 * 4) & 0x3F);
        result += SipHash.rotl(temp[4], (29 * 5) & 0x3F);
        result += SipHash.rotl(temp[5], (29 * 6) & 0x3F);
        result += SipHash.rotl(temp[6], (29 * 7) & 0x3F);
        result += SipHash.rotl(temp[7], (29 * 8) & 0x3F);

        result = SipHash.rotl(result, 24);

        // Wipe out lowest 64 bits in favor of the mixed bits
        self.workWord0 = result;
    }

    function hasColision(Instance memory self, Instance memory other)
        internal
        pure
        returns (bool)
    {
        uint64 val = self.workWord0 ^ other.workWord0;
        uint64 mask = (1 << 24) - 1;

        return (val & mask) == 0;
    }

    function isZero(Instance memory self)
        internal
        pure
        returns (bool)
    {
        return self.workWord0 == 0 || self.workWord1 == 0 ||
               self.workWord2 == 0 || self.workWord3 == 0 ||
               self.workWord4 == 0 || self.workWord5 == 0 ||
               self.workWord6 == 0;
    }
}