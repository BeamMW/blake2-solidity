// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import {SipHash} from "./SipHash.sol";

library StepElem {
    struct Instance {
        uint64[7] workWords;
    }

    function init(uint64 state0, uint64 state1, uint64 state2, uint64 state3, uint64 index)
        internal
        pure
        returns (Instance memory result)
    {
        uint8 i = 7;
        do {
            i--;
            result.workWords[i] = SipHash.siphash24(state0, state1, state2, state3, (index << 3) + i);
        } while(i > 0);
    }

    function mergeWith(Instance memory self, Instance memory other/*, uint32 remLem*/)
        internal
        pure
    {
        for (uint8 i = 0; i < 7; i++)
        {
            self.workWords[i] ^= other.workWords[i];
        }

        // TODO need to implement shift
    }

    function applyMix()
        internal
        pure
    {
        // TODO need to implement    
    }

    function hasColision(Instance memory self, Instance memory other)
        internal
        pure
        returns (bool)
    {
        uint64 val = self.workWords[0] ^ other.workWords[0];
        uint64 mask = (1 << 24) - 1;

        return (val & mask) == 0;
    }
}