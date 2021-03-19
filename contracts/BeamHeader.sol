// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./BeamHashIII.sol";

library BeamHeader {
    struct PoW {
        bytes indicies;
        bytes nonce;
        uint32 difficulty;
    }

    struct SystemState {
        uint64 height;
        bytes32 prev;
        bytes32 chainWork;
        bytes32 kernels;
        bytes32 definition;
        uint64 timestamp;
        PoW pow;
    }

    // TODO: Rewrite using assembly mload?
    function exactPoW(bytes memory raw)
        private
        pure
        returns (PoW memory pow)
    {
        uint32 nSolutionBytes = 104;
        uint32 nNonceBytes = 8;
        pow.indicies = new bytes(nSolutionBytes);
        pow.nonce = new bytes(nNonceBytes);

        uint32 index = 0;
        for (uint32 i = 0; i < nSolutionBytes; i++) {
            pow.indicies[i] = raw[index++];
        }
        for (uint32 i = 0; i < nNonceBytes; i++) {
            pow.nonce[i] = raw[index++];
        }
        for (uint32 i = 0; i < 4; i++) {
            uint32 temp = uint32(uint8(raw[index++]));
            temp <<= 8 * i;
            pow.difficulty ^= temp;
        }
    }

    function compileState(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow
    ) private pure returns (SystemState memory state) {
        state.height = height;
        state.prev = prev;
        state.chainWork = chainWork;

        state.kernels = kernels;
        state.definition = definition;
        state.timestamp = timestamp;

        state.pow = exactPoW(pow);
    }

    function findFork(uint64 height)
        private
        pure
        returns (uint8)
    {
        if (height >= 777777) return 2;
        if (height >= 321321) return 1;
        return 0;
    }

    function getForkHash(uint8 fork)
        private
        pure
        returns (uint256)
    {
        if (fork == 2) {
            return 0x1ce8f721bf0c9fa7473795a97e365ad38bbc539aab821d6912d86f24e67720fc;
        }
        if (fork == 1) {
            return 0x6d622e615cfd29d0f8cdd9bdd73ca0b769c8661b29d7ba9c45856c96bc2ec5bc;
        }
        return 0xed91a717313c6eb0e3f082411584d0da8f0c8af2a4ac01e5af1959e0ec4338bc;
    }

    function encodeUint(uint value)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encoded;
        for (; value >= 0x80; value >>= 7) {
            encoded = abi.encodePacked(encoded, uint8(uint8(value) | 0x80));
        }
        return abi.encodePacked(encoded, uint8(value));
    }

    function encodeState(SystemState memory state, bool total)
        private
        pure
        returns (bytes memory)
    {
        bytes memory prefix = abi.encodePacked(
            encodeUint(state.height),
            state.prev,
            state.chainWork
        );
        bytes memory element = abi.encodePacked(
            state.kernels,
            state.definition,
            encodeUint(state.timestamp),
            encodeUint(state.pow.difficulty)
        );
        bytes memory encoded = abi.encodePacked(prefix, element);

        uint8 iFork = findFork(state.height);
        if (iFork >= 2) {
            encoded = abi.encodePacked(encoded, getForkHash(iFork));
        }

        if (total) {
            encoded = abi.encodePacked(
                encoded,
                state.pow.indicies,
                state.pow.nonce
            );
        }

        return encoded;
    }

    function getHashInternal(SystemState memory state, bool total)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encodedState = encodeState(state, total);
        return abi.encodePacked(sha256(encodedState));
    }

    function isValid(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow
    ) internal view returns (bool) {
        SystemState memory state = compileState(
            height,
            prev,
            chainWork,
            kernels,
            definition,
            timestamp,
            pow
        );

        //  TODO: check difficulty

        // get pre-pow
        bytes memory prepowHash = getHashInternal(state, false);

        return BeamHashIII.Verify(prepowHash, state.pow.nonce, state.pow.indicies);
    }

    function getHeaderHashInternal(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow,
        bool total
    ) internal pure returns (bytes memory) {
        SystemState memory state = compileState(
            height,
            prev,
            chainWork,
            kernels,
            definition,
            timestamp,
            pow
        );

        return getHashInternal(state, total);
    }
}
