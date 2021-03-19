// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Blake2b.sol";
import {SipHash} from "./SipHash.sol";
import "./StepElem.sol";

library BeamHashIII {
    using Blake2b for Blake2b.Instance;
    using StepElem for StepElem.Instance;

    function siphash24(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 nonce)
        public
        pure
        returns (uint64)
    {
        return SipHash.siphash24(state0, state1, state2, state3, nonce);
    }

    function indexDecoder(bytes memory soln)
        public
        pure
        returns (uint32[32] memory result)
    {
        uint8 maskSize = 25;
        uint32 mask = 1;
        mask = ((mask << maskSize) - 1);

        uint8 currentSize = 0;
        uint32 buffer = 0;
        uint8 index = 0;

        uint32[32] memory ret;
        // check size of soln
        for (uint8 i = 0; i < 100; i++)
        {
            uint32 tmp = uint8(soln[i]);
            tmp <<= currentSize;
            buffer |= tmp;
            currentSize += 8;

            if (currentSize >= maskSize)
            {
                ret[index] = buffer & mask; 
                index++;
                buffer >>= maskSize;
                currentSize -= maskSize;
            }
        }

        result = ret;
    }

    uint32 constant kColisionBitSize = 24;
    uint32 constant kWorkBitSize = 448;
    // Beam blake2b personalization!
    // zero padded to 32 bytes
    bytes constant personalization = hex"4265616d2d506f57c00100000500000000000000000000000000000000000000";

    function Verify(bytes memory dataHash, bytes memory nonce, bytes memory soln)
        internal
        view
        returns (bool)
    {
        bytes memory buffer = new bytes(128);

        // TODO it's bad code. need change it
        uint16 ind = 0;
        for (uint16 i = 0; i < dataHash.length; i++) {
            buffer[ind] = dataHash[i];
            ind++;
        }
        for (uint16 i = 0; i < nonce.length; i++) {
            buffer[ind] = nonce[i];
            ind++;
        }
        for (uint16 i = 0; i < 4; i++) {
            buffer[ind] = soln[100 + i];
            ind++;
        }

        Blake2b.Instance memory instance = Blake2b.init(hex"", 32, personalization);
        bytes memory tmp = instance.finalize(buffer, dataHash.length + nonce.length + 4);
        uint64 state0 = StepElem.toUint64(tmp, 0);
        uint64 state1 = StepElem.toUint64(tmp, 8);
        uint64 state2 = StepElem.toUint64(tmp, 16);
        uint64 state3 = StepElem.toUint64(tmp, 24);
        uint32[32] memory indices = indexDecoder(soln);

        StepElem.Instance[32] memory elemLite;
        for (uint8 i = 0; i < elemLite.length; i++)
        {
            elemLite[i] = StepElem.init(state0, state1, state2, state3, indices[i]);
        }

        uint32 round = 1;
        for (uint32 step = 1; step < indices.length; step <<= 1) {
            for (uint32 i0 = 0; i0 < indices.length;) {
                uint32 remLen = kWorkBitSize - (round - 1) * kColisionBitSize;

                if (round == 5) remLen -= 64;

                elemLite[i0].applyMix(remLen, indices, i0, step);
                uint32 i1 = i0 + step;
                elemLite[i1].applyMix(remLen, indices, i1, step);

                if (!elemLite[i0].hasColision(elemLite[i1]))
                    return false;

                if (indices[i0] >= indices[i1])
                    return false;

                remLen = kWorkBitSize - round * kColisionBitSize;
                if (round == 4) remLen -= 64;
                if (round == 5) remLen = kColisionBitSize;

                elemLite[i0].mergeWith(elemLite[i1], remLen);

                i0 = i1 + step;
            }
            round++;
        }

        for (uint8 j = 0; j < elemLite[0].workWords.length; j++) {
            if (elemLite[0].workWords[j] != 0)
                return false;
        }

        // ensure all the indices are distinct
        for (uint8 i = 0; i < indices.length - 1; i++) {
            for (uint8 j = i + 1; j < indices.length; j++) {
                if (indices[i] == indices[j])
                    return false;
            }
        }

        return true;
    }
}
