// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Blake2b.sol";
import "./StepElem.sol";

library BeamHashIII {
    using Blake2b for Blake2b.Instance;
    using StepElem for StepElem.Instance;

    function indexDecoder(bytes memory soln)
        public
        pure
        returns (uint32[32] memory result)
    {
        uint maskSize = 25;
        uint mask = 1;
        mask = ((mask << maskSize) - 1);

        uint currentSize = 0;
        uint buffer = 0;
        uint index = 0;

        // check size of soln
        for (uint i = 0; i < 100; i++)
        {
            buffer |= uint(uint8(soln[i])) << currentSize;
            currentSize += 8;

            if (currentSize >= maskSize)
            {
                result[index] = uint32(buffer & mask);
                index++;
                buffer >>= maskSize;
                currentSize -= maskSize;
            }
        }
    }

    uint32 constant kColisionBitSize = 24;
    uint32 constant kWorkBitSize = 448;
    // Beam blake2b personalization!
    // zero padded to 32 bytes
    bytes constant personalization = hex"4265616d2d506f57c00100000500000000000000000000000000000000000000";

    function Verify(bytes32 dataHash, bytes8 nonce, bytes memory indicesRaw)
        internal
        view
        returns (bool)
    {
        require(indicesRaw.length == 104, "BeamHashIII: unexpected size of soln.");
        bytes memory buffer = new bytes(128);
        {
            bytes4 temp;
            assembly {
                // save hash to buffer
                mstore(add(buffer, 32), dataHash)
                // save nonce to buffer
                mstore(add(buffer, 64), nonce)

                // load additional 4 bytes from indicesRaw:
                // get last 32 bytes and shift left 28 bytes
                temp := shl(224, mload(add(indicesRaw, 104)))
                // save to buffer, offset: 32 + 32 + 8 = 72
                mstore(add(buffer, 72), temp)
            }
        }

        Blake2b.Instance memory instance = Blake2b.init(hex"", 32, personalization);
        bytes memory tmp = instance.finalize(buffer, dataHash.length + nonce.length + 4);
        uint64 state0 = StepElem.toUint64(tmp, 0);
        uint64 state1 = StepElem.toUint64(tmp, 8);
        uint64 state2 = StepElem.toUint64(tmp, 16);
        uint64 state3 = StepElem.toUint64(tmp, 24);
        uint32[32] memory indices = indexDecoder(indicesRaw);

        StepElem.Instance[32] memory elemLite;
        for (uint i = 0; i < elemLite.length; i++)
        {
            elemLite[i] = StepElem.init(state0, state1, state2, state3, indices[i]);
        }
 
        uint round = 1;
        uint i1;
        for (uint step = 1; step < indices.length; step <<= 1) {
            for (uint i0 = 0; i0 < indices.length;) {
                uint remLen = kWorkBitSize - (round - 1) * kColisionBitSize;

                if (round == 5) remLen -= 64;

                elemLite[i0].applyMix(remLen, indices, i0, step);
                i1 = i0 + step;
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

        if (!elemLite[0].isZero())
            return false;

        // ensure all the indices are distinct
        for (uint i = 0; i < indices.length - 1; i++) {
            for (uint j = i + 1; j < indices.length; j++) {
                if (indices[i] == indices[j])
                    return false;
            }
        }

        return true;
    }
}
