// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ValidatorSetStorage.sol";
import "../interfaces/IGateway.sol";

contract Gateway is ValidatorSetStorage, IGateway {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;

    /// @custom:security write-protection="onlySystemCall()"
    // slither-disable-next-line protected-vars
    mapping(uint256 => bool) public processedEvents;

    event BridgeMessageResult(uint256 indexed counter, bool indexed status, bytes message);

    event BridgeMessageEvent(uint256 indexed id, address indexed sender, address indexed receiver, bytes data);

    /**
     *
     * @notice Generates sync state event based on receiver and data.
     * Anyone can call this method to emit an event. Receiver on Polygon should add check based on sender.
     *
     * @param receiver Receiver address on Polygon chain
     * @param data Data to send on Polygon chain
     *
     */
    function sendBridgeMsg(address receiver, bytes calldata data) external {
        // check receiver
        require(receiver != address(0), "INVALID_RECEIVER");
        // check data length
        require(data.length <= MAX_LENGTH, "EXCEEDS_MAX_LENGTH");

        // State sync id will start with 1
        emit BridgeMessageEvent(++counter, msg.sender, receiver, data);
    }

    /**
     * @notice receives the batch of messages and executes them
     * @param batch batch of messages
     * @param signature the aggregated signature submitted by the proposer
     * @param bitmap bitmap of which validators signed the message
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(
        BridgeMessageBatch calldata batch,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) external {
        _verifyBatch(batch);

        bytes memory hash = abi.encode(keccak256(abi.encode(batch)));
        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signature, bitmap);

        uint256 length = batch.messages.length;
        for (uint256 i = 0; i < length; ) {
            _executeBridgeMessage(batch.messages[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    function _verifyBatch(BridgeMessageBatch calldata batch) private view {
        require(batch.messages.length > 0, "EMPTY_BATCH");

        uint256 destinationChainId = block.chainid;
        require(batch.destinationChainId == destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
        for (uint256 i = 0; i < batch.messages.length; ) {
            BridgeMessage memory message = batch.messages[i];
            require(message.sourceChainId == batch.sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
            unchecked {
                ++i;
            }
        }
    }

    function _executeBridgeMessage(BridgeMessage calldata message) private {
        require(!processedEvents[message.id], "DestinationGateway: BRIDGE_MESSAGE_IS_ALREADY_PROCESSED");
        // Skip transaction if client has added flag, or receiver has no code
        if (message.receiver.code.length == 0) {
            emit BridgeMessageResult(message.id, false, "");
            return;
        }

        processedEvents[message.id] = true;

        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-no-eth
        (bool success, bytes memory returnData) = message.receiver.call(
            abi.encodeWithSignature(
                "onStateReceive(uint256,address,bytes)",
                message.id,
                message.sender,
                message.payload
            )
        );

        // if bridge message fails, revert flag
        if (!success) processedEvents[message.id] = false;

        // emit a ResultEvent indicating whether invocation of bridge message was successful or not
        // slither-disable-next-line reentrancy-events
        emit BridgeMessageResult(message.id, success, returnData);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
