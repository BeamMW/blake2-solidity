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

    function reverse32(uint32 value)
        internal
        pure
        returns (uint32)
    {
        // swap bytes
        value = ((value & 0xFF00FF00) >> 8) |
                ((value & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        value = (value >> 16) | (value << 16);

        return value;
    }
}