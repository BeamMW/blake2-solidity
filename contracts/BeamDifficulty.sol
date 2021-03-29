// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

library BeamDifficulty {
    uint32 constant kMantissaBits = 24;

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

    function isTargetReached(uint256 rawDifficulty, uint256 target)
        internal
        pure
        returns (bool)
    {
        (, bytes32 hightHalf) = mul512(rawDifficulty, target);

        // difficulty.length - (kMantissaBits >> 3) = 32 - (24 >> 3) = 29
        uint8 n = 29;
        for (uint16 i = 0; i < n; i++) {
            if (hightHalf[i] != 0) {
                return false;
            }
        }
        return true;
    }

    function unpack(uint32 packed)
        internal
        pure
        returns (uint256 rawDifficulty)
    {
        uint32 order = packed >> kMantissaBits;
        uint32 leadingBit = uint32(1 << kMantissaBits);
        uint32 mantissa = leadingBit | (packed & (leadingBit - 1));

        rawDifficulty = uint256(mantissa) << order;
    }
}