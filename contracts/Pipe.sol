// SPDX-License-Identifier: MIT
pragma solidity ^0.7.2;

contract Pipe {
    struct Message {
        uint256 value;
        bool validated;
    }

    struct LocalMessage {
        address receiver;
        uint256 value;
    }

    mapping (address => Message) m_messages;
    LocalMessage[] m_localMessages;

    function pushMessage(address receiver, uint256 value) public {
        require(value > 0, "value should be not zero");
        require(m_messages[receiver].value == 0, "message is exist");

        m_messages[receiver].value = value;
        m_messages[receiver].validated = false;
    }

    function validateMessage(address receiver) public {
        m_messages[receiver].validated = true;
    }

    function getMessage(address receiver) public returns (uint256) {
        require(m_messages[receiver].validated, "message should be validated");

        Message memory tmp = m_messages[receiver];

        delete m_messages[receiver];

        return tmp.value;
    }

    function createMessage(address receiver, uint256 value) public {
        LocalMessage memory tmp;
        tmp.receiver = receiver;
        tmp.value = value;

        m_localMessages.push(tmp);
    }

    function getMessageToSend() public view returns (address receiver, uint256 value) {
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