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

    function proccessMessage(uint packageId, uint msgId) public {
        bytes memory value = Pipe(m_pipeAddress).getRemoteMessage(packageId, msgId);

        // TODO: change
        // parse msg: [address zero padded to 33bytes][uint64 value]
        address receiver;
        bytes8 tmp;
        assembly {
            receiver := shr(96, mload(add(value, 32)))
            tmp := mload(add(value, 65))
        }
        uint64 amount = BeamUtils.reverse64(uint64(tmp));

        IERC20(m_beamToken).safeTransfer(receiver, amount);
    }

    function lock(address receiver, uint256 value) public {
        IERC20(m_beamToken).safeTransferFrom(msg.sender, address(this), value);

        Pipe(m_pipeAddress).pushLocalMessage(receiver, value);
    }
}