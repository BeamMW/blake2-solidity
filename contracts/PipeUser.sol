// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "./Pipe.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract PipeUser {
    using SafeERC20 for IERC20;
    address m_pipeAddress;
    address m_beamToken;

    constructor(address pipeAddress, address beamToken) {
        m_pipeAddress = pipeAddress;
        m_beamToken = beamToken;
    }

    function proccessMessage(address receiver) public {
        uint256 value = Pipe(m_pipeAddress).getMessage(receiver);

        IERC20(m_beamToken).safeTransfer(receiver, value);
    }

    function lock(address receiver, uint256 value) public {
        IERC20(m_beamToken).safeTransferFrom(msg.sender, address(this), value);

        Pipe(m_pipeAddress).createMessage(receiver, value);
    }
}