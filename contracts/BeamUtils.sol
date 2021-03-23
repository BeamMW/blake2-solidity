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
        returns (bytes memory)
    {
        bytes memory encoded = abi.encodePacked(
            "beam.contract.val\x00",
            BeamUtils.encodeUint(key.length),
            key,
            BeamUtils.encodeUint(value.length),
            value
        );

        return abi.encodePacked(sha256(encoded));
    }
}