// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./BeamUtils.sol";
import "./BeamHeader.sol";
import "./BeamDifficulty.sol";

contract BeamUtilsTest {
    function getContractVariableHash(bytes32 contractId, uint8 keyTag, bytes memory key, bytes32 value)
        public
        pure
        returns (bytes32)
    {
        // full key of variable of beam pipe contract: [ContractID][tag][key]
        bytes memory fullKeyEncoded = abi.encodePacked(
            contractId,
            BeamUtils.encodeUint(keyTag),
            key
        );

        return BeamUtils.getContractVariableHash(fullKeyEncoded, abi.encodePacked(value));
    }

    function getContractVariableHash2(bytes memory key, bytes memory value)
        public
        pure
        returns (bytes32)
    {
        return BeamUtils.getContractVariableHash(key, value);
    }

    function interpretMerkleProof(bytes32 variableHash, bytes memory proof)
        public
        pure
        returns (bytes32)
    {
        return BeamUtils.interpretMerkleProof(variableHash, proof);
    }

    function validateVariable(
        // params of block
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow,
        bytes32 rulesHash,
        // variable's params
        bytes memory key,
        bytes memory value,
        bytes memory proof
    ) public view returns (bool) {
        require(BeamHeader.isValid(height, prev, chainWork, kernels, definition, timestamp, pow, rulesHash), 'invalid header.');

        bytes32 variableHash = BeamUtils.getContractVariableHash(key, abi.encodePacked(value));
        bytes32 rootHash = BeamUtils.interpretMerkleProof(variableHash, proof);

        return rootHash == definition;
    }

    function testMul512(uint256 a, uint256 b)
        public
        pure
        returns (bytes32 r0, bytes32 r1)
    {
        (r0, r1) = BeamDifficulty.mul512(a, b);
    }

    function isDifficultyTargetReached(uint256 rawDifficulty, uint256 target)
        public
        pure
        returns (bool)
    {
        return BeamDifficulty.isTargetReached(rawDifficulty, target);
    }

    function testDifficultyUnpack(uint32 packed)
        public
        pure
        returns (bytes32)
    {
        return bytes32(BeamDifficulty.unpack(packed));
    }
}