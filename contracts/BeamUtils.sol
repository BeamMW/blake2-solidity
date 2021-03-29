// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library BeamUtils {
    function encodeUint(uint value)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory encoded;
        for (; value >= 0x80; value >>= 7) {
            encoded = abi.encodePacked(encoded, uint8(uint8(value) | 0x80));
        }
        return abi.encodePacked(encoded, uint8(value));
    }

    function getContractVariableHash(bytes memory key, bytes memory value)
        internal
        pure
        returns (bytes32)
    {
        bytes memory encoded = abi.encodePacked(
            "beam.contract.val\x00",
            BeamUtils.encodeUint(key.length),
            key,
            BeamUtils.encodeUint(value.length),
            value
        );

        return sha256(encoded);
    }

    function interpretMerkleProof(bytes32 variableHash, bytes memory proof)
        internal
        pure
        returns (bytes32 rootHash)
    {
        // 33 - 1 byte for flag onRight and 32 byte for leaf hash
        require(proof.length % 33 == 0, "unexpected lenght of the proof.");
        // TODO: check proof max size
        require(proof.length < 255 * 33, "the length of the proof is too long.");

        rootHash = variableHash;
        bytes32 secondHash;
        for (uint16 index = 0; index < proof.length; index += 33) {
            assembly {
                secondHash := mload(add(add(proof, 33), index))
            }

            if (proof[index] != 0x01) {
                rootHash = sha256(abi.encodePacked(secondHash, rootHash));
            }
            else {
                rootHash = sha256(abi.encodePacked(rootHash, secondHash));
            }
        }
    }

    function mul512(uint256 a, uint256 b)
        internal
        pure
        returns (bytes32 r0, bytes32 r1)
    {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a,b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    function isDifficultyTargetReached(uint256 rawDifficulty, uint256 target)
        internal
        pure
        returns (bool)
    {
        (, bytes32 hightHalf) = mul512(rawDifficulty, target);

        // difficulty.length - (MantissaBits >> 3) = 32 - (24 >> 3) = 29
        uint8 n = 29;
        for (uint16 i = 0; i < n; i++) {
            if (hightHalf[i] != 0) {
                return false;
            }
        }
        return true;
    }
}