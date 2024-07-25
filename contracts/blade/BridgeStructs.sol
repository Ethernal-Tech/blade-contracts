// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract BridgeStructs {
    /// @custom:security write-protection="onlySystemCall()"
    // slither-disable-next-line protected-vars
    mapping(uint256 => bool) processedEvents;

    bytes32 public constant DOMAIN_VALIDATOR_SET = keccak256("DOMAIN_VALIDATOR_SET");

    bytes32 public constant DOMAIN = keccak256("DOMAIN_BRIDGE");

    event BridgeMessageResult(uint256 indexed counter, bool indexed status, bytes message);

    /**
     * @param id id of message
     * @param sourceChainId id of source chain
     * @param destinationChainId id of destination chain
     * @param sender sender account of this bridge message
     * @param receiver receiver account of this bridge message
     * @param payload payload
     */
    struct BridgeMessage {
        uint256 id;
        uint256 sourceChainId;
        uint256 destinationChainId;
        address sender;
        address receiver;
        bytes payload;
    }

    /**
     * @param messages list of all messages in batch
     * @param sourceChainId id of chain which is source of batch
     * @param destinationChainId id of chain which is destination of batch
     */
    struct BridgeMessageBatch {
        BridgeMessage[] messages;
        uint256 sourceChainId;
        uint256 destinationChainId;
    }
}
