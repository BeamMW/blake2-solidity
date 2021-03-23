// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "./BeamUtils.sol";

contract Pipe {
    // config:
    // remote cfg:
    // uint32 packageMaxMsgs;
    // uint64 packageMaxDiffHeightToClose;
    // local cfg:
    // bytes32 rulesRemote; // ?
    // uint256 comissionPerMsg;
    // uint256 stakeForRemoteMsg;
    // uint64  disputePeriod;
    // uint64  contenderWaitPeriod;

    // incoming messages
    struct RemoteMessage {
        // header:
        // uint64 package_id;
        // uint64 msg_id;
        // address msg_receiver - eth contract address
        // bytes32 msg_sender - beam contract id

        // body
        uint256 value;
        bool validated;
    }

    // outgoing messages
    struct LocalMessage {
        // header:
        // uint64 pckg_id;
        // uint64 msg_id;
        // address msg_sender; // eth contract address
        // bytes32 msg_receiver; // beam contract id

        // body
        address receiver;
        uint256 value;
    }

    mapping (address => RemoteMessage) m_remoteMessages;
    LocalMessage[] m_localMessages;

    function pushRemoteMessage(address receiver, uint256 value)
        public
    {
        require(value > 0, "value should be not zero");
        require(m_remoteMessages[receiver].value == 0, "message is exist");

        m_remoteMessages[receiver].value = value;
        m_remoteMessages[receiver].validated = false;
    }

    function validateRemoteMessage(address receiver)
        public
    {
        m_remoteMessages[receiver].validated = true;

        // validate block header & proof of msg
    }

    function getContractVariableHash2(bytes32 contractId, uint8 keyTag, bytes memory key, bytes32 value)
        public
        pure
        returns (bytes memory)
    {
        // full key of variable of beam pipe contract: [ContractID][tag][key]
        bytes memory fullKeyEncoded = abi.encodePacked(
            contractId,
            BeamUtils.encodeUint(keyTag),
            key
        );

        return BeamUtils.getContractVariableHash(fullKeyEncoded, abi.encodePacked(value));
    }

    function getRemoteMessage(address receiver)
        public
        returns (uint256)
    {
        require(m_remoteMessages[receiver].validated, "message should be validated");

        RemoteMessage memory tmp = m_remoteMessages[receiver];

        delete m_remoteMessages[receiver];

        return tmp.value;
    }

    function pushLocalMessage(address receiver, uint256 value)
        public
    {
        LocalMessage memory tmp;
        tmp.receiver = receiver;
        tmp.value = value;

        m_localMessages.push(tmp);
    }

    function getLocalMessageToSend()
        public
        view
        returns (address receiver, uint256 value)
    {
        require(m_localMessages.length > 0, "empty");
        LocalMessage memory tmp = m_localMessages[0];

        /*for (uint i = 0; i < m_localMessages.length - 1; i++) {
            m_localMessages[i] = m_localMessages[i+1];
        }

        m_localMessages.pop();*/
        
        receiver = tmp.receiver;
        value = tmp.value;
    }
}