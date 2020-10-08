pragma solidity ^0.5.0;

import "./Blake2b.sol";

contract CultivationTest {
    using Blake2b for Blake2b.Instance;

    bytes constant FORK_HASH = hex"ccabdcee29eb38842626ad1155014e2d7fc1b00d0a70ccb3590878bdb7f26a02";

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

    function checkPoW(bytes memory raw)
        public
        pure
        returns (
            bytes memory indicies,
            bytes memory nonce,
            uint32 difficulty
        )
    {
        PoW memory pow = exactPoW(raw);
        return (pow.indicies, pow.nonce, pow.difficulty);
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

    function encodeState(SystemState memory state, bool total)
        private
        pure
        returns (bytes memory)
    {
        bytes memory prefix = abi.encodePacked(
            state.height,
            state.prev,
            state.chainWork
        );
        bytes memory element = abi.encodePacked(
            state.kernels,
            state.definition,
            state.timestamp
        );
        bytes memory fork = FORK_HASH; // TODO: find correct fork
        bytes memory encoded = abi.encodePacked(prefix, element, fork);
        if (total) {
            encoded = abi.encodePacked(
                encoded,
                state.pow.indicies,
                state.pow.nonce
            );
        }

        return encoded;
    }

    function process(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow
    ) public pure returns (bytes memory) {
        SystemState memory state = compileState(
            height,
            prev,
            chainWork,
            kernels,
            definition,
            timestamp,
            pow
        );
        bytes memory encodedState = encodeState(state, true);
        return abi.encodePacked(sha256(encodedState));
    }

    function testOneBlock(bytes memory input, uint256 input_len)
        public
        view
        returns (bytes memory)
    {
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64);
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
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64);
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
            instance.reset(hex"", 64);
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
        Blake2b.Instance memory instance = Blake2b.init(hex"", 64);
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
            instance.reset(hex"", 64);
        }
        assert(ret == 0);
    }
}
