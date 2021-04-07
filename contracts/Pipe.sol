// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

import "./BeamHeader.sol";
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
        uint packageId;
        uint msgId;
        // eth contract address
        // TODO: should be changed when Beam side will be ready 
        // address msgReceiver;
        bytes32 msgReceiver;
        // beam contract id
        bytes32 msgSender;

        // body
        bytes value;
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

    bytes32 m_remotePipeId;
    mapping (bytes32 => RemoteMessage) m_remoteMessages;
    LocalMessage[] m_localMessages;

    function setRemote(bytes32 remoteContractId)
        public
    {
        m_remotePipeId = remoteContractId;
    }

    // TODO: add support multiple msgs
    function pushRemoteMessage(uint packageId,
                               uint msgId,
                               bytes32 msgSender,       // beam contract id
                               bytes32 msgReceiver,     // eth contract address
                               bytes memory messageBody)
        public
    {
        bytes32 key = keccak256(abi.encodePacked(packageId, msgId));

        require(m_remoteMessages[key].value.length == 0, "message is exist");

        m_remoteMessages[key].packageId = packageId;
        m_remoteMessages[key].msgId = msgId;
        m_remoteMessages[key].msgReceiver = msgReceiver;
        m_remoteMessages[key].msgSender = msgSender;
        m_remoteMessages[key].value = messageBody;
        m_remoteMessages[key].validated = false;
    }

    function getPackageKey(uint packageId)
        private
        view
        returns (bytes memory)
    {
        // [contract_id,KeyTag::Internal(uint8 0),KeyType::OutCheckpoint(uint8 2),index_BE(uint32 'packageId')]
        return abi.encodePacked(m_remotePipeId, uint8(0), uint8(2), uint32(packageId));
    }

    function getMsgHash(bytes32 previousHash, RemoteMessage memory message)
        private
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked("b.msg\x00",
                      previousHash,
                      // full msg size
                      BeamUtils.encodeUint(message.msgReceiver.length + message.msgSender.length + message.value.length),
                      // msgHdr: sender/receiver
                      message.msgSender,
                      message.msgReceiver,
                      // msg body
                      message.value));
    }

    function validateRemoteMessage(uint packageId,
                                   uint msgId, 
                                   // params of block
                                   bytes32 prev,
                                   bytes32 chainWork,
                                   bytes32 kernels,
                                   bytes32 definition,
                                   uint64 height,
                                   uint64 timestamp,
                                   bytes memory pow,
                                   bytes32 rulesHash,
                                   bytes memory proof)
        public
    {
        bytes32 key = keccak256(abi.encodePacked(packageId, msgId));
        require(!m_remoteMessages[key].validated, "already verified.");
        
        // validate block header & proof of msg
        // TODO: uncomment when stop using FakePow
        // require(BeamHeader.isValid(prev, chainWork, kernels, definition, height, timestamp, pow, rulesHash), 'invalid header.');

        bytes32 packageValue = getMsgHash(0, m_remoteMessages[key]);
        bytes memory variableKey = getPackageKey(packageId);

        bytes32 variableHash = BeamUtils.getContractVariableHash(variableKey, abi.encodePacked(packageValue));
        bytes32 rootHash = BeamUtils.interpretMerkleProof(variableHash, proof);

        require(rootHash == definition, "invalid proof");

        m_remoteMessages[key].validated = true;
    }

    function getRemoteMessage(uint packageId, uint msgId)
        public
        returns (bytes memory)
    {
        bytes32 key = keccak256(abi.encodePacked(packageId, msgId));
        require(m_remoteMessages[key].validated, "message should be validated");

        RemoteMessage memory tmp = m_remoteMessages[key];

        delete m_remoteMessages[key];

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