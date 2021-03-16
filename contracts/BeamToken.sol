// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract BeamToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("BeamToken", "BEAM") {
        _mint(msg.sender, initialSupply);
    }
}