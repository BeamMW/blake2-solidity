// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./BeamHashIII.sol";
import "./BeamUtils.sol";
import "./BeamDifficulty.sol";

library BeamHeader {
    struct PoW {
        bytes indicies;
        bytes8 nonce;
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

    function exactPoW(bytes memory raw)
        private
        pure
        returns (PoW memory pow)
    {
        uint32 nSolutionBytes = 104;
        require(raw.length >= nSolutionBytes + 8 + 4, "unexpected rawPoW length!");
        bytes memory indicies = new bytes(nSolutionBytes);

        assembly {
            mstore(add(indicies, 32), mload(add(raw, 32)))
            mstore(add(indicies, 64), mload(add(raw, 64)))
            mstore(add(indicies, 96), mload(add(raw, 96)))
            mstore(add(indicies, 128), mload(add(raw, 128)))

            // load last 8 bytes
            mstore(add(indicies, 104), mload(add(raw, 104)))
        }
        pow.indicies = indicies;

        bytes8 nonce;
        assembly {
            nonce := shl(192, mload(add(raw, 112)))
        }
        pow.nonce = nonce;

        bytes4 diff;
        assembly {
            diff := shl(224, mload(add(raw, 116)))
        }
        pow.difficulty = BeamUtils.reverse32(uint32(diff));
    }

    function compileState(
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 height,
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
        returns (bytes32)
    {
        bytes memory encodedState = encodeState(state, total, rulesHash);
        return sha256(encodedState);
    }

    function isValid(
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 height,
        uint64 timestamp,
        bytes memory pow,
        bytes32 rulesHash
    ) internal view returns (bool) {
        SystemState memory state = compileState(
            prev,
            chainWork,
            kernels,
            definition,
            height,
            timestamp,
            pow
        );

        // checking difficulty
        uint256 rawDifficulty = BeamDifficulty.unpack(state.pow.difficulty);
        uint256 target = uint256(sha256(abi.encodePacked(state.pow.indicies)));
        if (!BeamDifficulty.isTargetReached(rawDifficulty, target))
            return false;

        // get pre-pow
        bytes32 prepowHash = getHashInternal(state, false, rulesHash);

        return BeamHashIII.Verify(prepowHash, state.pow.nonce, state.pow.indicies);
    }

    function getHeaderHashInternal(
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 height,
        uint64 timestamp,
        bytes memory pow,
        bool total,
        bytes32 rulesHash
    ) internal pure returns (bytes32) {
        SystemState memory state = compileState(
            prev,
            chainWork,
            kernels,
            definition,
            height,
            timestamp,
            pow
        );

        return getHashInternal(state, total, rulesHash);
    }
}
