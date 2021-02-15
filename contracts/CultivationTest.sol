pragma solidity ^0.5.0;

import "./Blake2b.sol";
import {SipHash} from "./SipHash.sol";

contract CultivationTest {
    uint256[3] private FORKS = [0xed91a717313c6eb0e3f082411584d0da8f0c8af2a4ac01e5af1959e0ec4338bc, 0x6d622e615cfd29d0f8cdd9bdd73ca0b769c8661b29d7ba9c45856c96bc2ec5bc, 0x1ce8f721bf0c9fa7473795a97e365ad38bbc539aab821d6912d86f24e67720fc];
    using Blake2b for Blake2b.Instance;

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
        view
        returns (uint256)
    {
        if (fork < FORKS.length) {
            return FORKS[fork];
        }
        return FORKS[0];
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
        view
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

    function process(
        uint64 height,
        bytes32 prev,
        bytes32 chainWork,
        bytes32 kernels,
        bytes32 definition,
        uint64 timestamp,
        bytes memory pow
    ) public view returns (bytes memory) {
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
        Blake2b.Instance memory instance = Blake2b.init(hex"", 32);
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

    function siphash24(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 nonce)
        public
        returns (uint64)
    {
        return SipHash.siphash24(state0, state1, state2, state3, nonce);
    }

    function indexDecoder(uint8[] memory soln)
        public
        returns (uint32[32] memory result)
    {
        uint8 maskSize = 25;
        uint32 mask = 1;
        mask = ((mask << maskSize) - 1);

        uint8 currentSize = 0;
        uint32 buffer = 0;
        uint8 index = 0;

        uint32[32] memory ret;
        // check size of soln
        for (uint8 i = 0; i < 100; i++)
        {
            uint32 tmp = soln[i];
            tmp <<= currentSize;
            buffer |= tmp;
            currentSize += 8;

            if (currentSize >= maskSize)
            {
                ret[index] = buffer & mask; 
                index++;
                buffer >>= maskSize;
                currentSize -= maskSize;
            }
        }

        result = ret;
    }

    function initStepElem(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 index)
        public
        returns (uint64[7] memory result)
    {
        uint8 i = 7;
        do {
            i--;
            result[i] = siphash24(state0, state1, state2, state3, (index << 3) + i);
        } while(i > 0);
    }

    function mergeWith(uint64[7] memory my, uint64[7] memory other/*, uint32 remLem*/)
        public
        returns (uint64[7] memory result)
    {
        for (uint8 i = 0; i < 7; i++)
        {
            result[i] = my[i] ^ other[i];
        }

        // TODO need to implement shift
    }

    function applyMix()
        public
    {

    }

    function hasColision(uint64[7] memory my, uint64[7] memory other)
        public
        returns (bool result)
    {
        uint64 val = my[0] ^ other[0];
        uint64 mask = (1 << 24) - 1;

        result = (val & mask) == 0;
    }
}
