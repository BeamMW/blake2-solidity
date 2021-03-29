// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Blake2b.sol";
import {SipHash} from "./SipHash.sol";
import "./BeamHeader.sol";
import "./BeamHashIII.sol";

contract CultivationTest {
    using Blake2b for Blake2b.Instance;
    using StepElem for StepElem.Instance;

    function getHeaderHash(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow,
        bool full,
        bytes32 rulesHash
    ) public pure returns (bytes memory) {
        return BeamHeader.getHeaderHashInternal(
            height,
            prev,
            chainWork,
            kernels,
            definition,
            timestamp,
            pow,
            full,
            rulesHash
        );
    }

    function isHeaderValid(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow,
        bytes32 rulesHash
    ) public view returns (bool) {
        return BeamHeader.isValid(height, prev, chainWork, kernels, definition, timestamp, pow, rulesHash);
    }

    function testOneBlock(bytes memory input, uint256 input_len)
        public
        view
        returns (bytes memory)
    {
        Blake2b.Instance memory instance = Blake2b.init(hex"", 32, hex"");
        return instance.finalize(input, input_len);
    }

    // This only implements some benchmark based on these descriptions
    //   https://forum.zcashcommunity.com/t/calculate-solutionsize/21042/2
    // and
    //   https://github.com/zcash/zcash/blob/996fccf267eedbd512619acc45e6d3c1aeabf3ab/src/crypto/equihash.cpp#L716
    function equihashTestN200K9() public view returns (uint256 ret) {
        bytes memory scratch = new bytes(128);
        bytes memory scratch_ptr;
        assembly {
            scratch_ptr := add(scratch, 32)
        }
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64, hex"");
        for (uint256 i = 0; i < 512; i++) {
            assembly {
                // This would be a 32-bit little endian number in Equihash
                mstore(scratch_ptr, i)
            }
            bytes memory hash = instance.finalize(scratch, 4);
            assembly {
                ret := xor(ret, mload(add(hash, 32)))
                ret := xor(ret, mload(add(hash, 64)))
            }
            instance.reset(hex"", 64, hex"");
        }
    }

    function equihashTestN200K9(uint32[512] memory solutions)
        public
        view
        returns (uint256 ret)
    {
        bytes memory scratch = new bytes(128);
        bytes memory scratch_ptr;
        assembly {
            scratch_ptr := add(scratch, 32)
        }
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64, hex"");
        for (uint256 i = 0; i < 512; i++) {
            uint32 solution = solutions[i];
            assembly {
                // This would be a 32-bit little endian number in Equihash
                mstore(scratch_ptr, solution)
            }
            bytes memory hash = instance.finalize(scratch, 4);
            assembly {
                ret := xor(ret, mload(add(hash, 32)))
                ret := xor(ret, mload(add(hash, 64)))
            }
            instance.reset(hex"", 64, hex"");
        }
        assert(ret == 0);
    }

    function siphash24(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 nonce)
        public
        pure
        returns (uint64)
    {
        return SipHash.siphash24(state0, state1, state2, state3, nonce);
    }

    function VerifyBeamPow(bytes memory dataHash, bytes memory nonce, bytes memory soln)
        public
        view
        returns (bool)
    {
        return BeamHashIII.Verify(dataHash, nonce, soln);
    }
}
