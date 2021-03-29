// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./BeamHashIII.sol";
import "./BeamUtils.sol";
import "./BeamDifficulty.sol";

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

    function encodeState(SystemState memory state, bool total, bytes32 rulesHash)
        private
        pure
        returns (bytes memory)
    {
        bytes memory prefix = abi.encodePacked(
            BeamUtils.encodeUint(state.height),
            state.prev,
            state.chainWork
        );
        bytes memory element = abi.encodePacked(
            state.kernels,
            state.definition,
            BeamUtils.encodeUint(state.timestamp),
            BeamUtils.encodeUint(state.pow.difficulty)
        );
        bytes memory encoded = abi.encodePacked(prefix, element);
        // support only fork2 and higher
        encoded = abi.encodePacked(encoded, rulesHash);

        if (total) {
            encoded = abi.encodePacked(
                encoded,
                state.pow.indicies,
                state.pow.nonce
            );
        }

        return encoded;
    }

    function getHashInternal(SystemState memory state, bool total, bytes32 rulesHash)
        private
        pure
        returns (bytes memory)
    {
        bytes memory encodedState = encodeState(state, total, rulesHash);
        return abi.encodePacked(sha256(encodedState));
    }

    function isValid(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow,
        bytes32 rulesHash
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

        // checking difficulty
        uint256 rawDifficulty = BeamDifficulty.unpack(state.pow.difficulty);
        uint256 target = uint256(sha256(abi.encodePacked(state.pow.indicies)));
        if (!BeamDifficulty.isTargetReached(rawDifficulty, target))
            return false;

        // get pre-pow
        bytes memory prepowHash = getHashInternal(state, false, rulesHash);

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
        bool total,
        bytes32 rulesHash
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

        return getHashInternal(state, total, rulesHash);
    }
}
