// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ValidatorSetStorage.sol";
import "../interfaces/IGateway.sol";
import "../lib/Merkle.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Gateway is ValidatorSetStorage, IGateway {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;

    /// @custom:security write-protection="onlySystemCall()"
    // slither-disable-next-line protected-vars
    mapping(uint256 => bool) public processedEvents;
    /// @custom:security write-protection="onlySystemCall()"
    // slither-disable-next-line protected-vars
    mapping(uint256 => bool) public processedEventsRollback;
    mapping(uint256 => BridgeMessage) bridgeMessages;

    event BridgeMessageResult(
        uint256 indexed counter,
        bool indexed status,
        uint256 sourceChainID,
        uint256 destinationChainID,
        bytes message
    );

    event BridgeMsg(
        uint256 indexed id,
        address indexed sender,
        address indexed receiver,
        uint256 sourceChainId,
        uint256 destinationChainId,
        bytes data
    );

    event BridgeBatchResult(
        uint256 startId,
        uint256 endId,
        uint256 sourceChainId,
        uint256 destinationChainId,
        bool isRollback
    );

    /**
     *
     * @notice Generates sync state event based on receiver and data.
     * Anyone can call this method to emit an event. Receiver on Polygon should add check based on sender.
     *
     * @param receiver Receiver address on Polygon chain
     * @param data Data to send on Polygon chain
     * @param destinationChainId Chain id of destination chain
     *
     */
    function sendBridgeMsg(address receiver, bytes calldata data, uint256 destinationChainId) external {
        // check receiver
        require(receiver != address(0), "INVALID_RECEIVER");
        // check data length
        require(data.length <= MAX_LENGTH, "EXCEEDS_MAX_LENGTH");
        // check destination chain id
        require(destinationChainId != 0, "INVALID_DESTINATION_CHAIN_ID");

        counter++;

        BridgeMessage memory message = BridgeMessage(
            counter,
            block.chainid,
            destinationChainId,
            msg.sender,
            receiver,
            data
        );

        bridgeMessages[counter] = message;

        // State sync id will start with 1
        emit BridgeMsg(counter, msg.sender, receiver, block.chainid, destinationChainId, data);
    }

    /**
     * @notice receives the batch of messages and executes them
     * @param bridgeBatch batch of messages
     * @param signature the aggregated signature submitted by the proposer
     * @param bitmap bitmap of which validators signed the message
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(
        BridgeMessageBatch calldata bridgeBatch,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) external virtual {
        if (bridgeBatch.isRollback) {
            _verifyRollbackBatch(bridgeBatch.messages);
        } else {
            _verifyBatch(bridgeBatch.messages);
        }

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    bridgeBatch.messages,
                    bridgeBatch.sourceChainId,
                    bridgeBatch.destinationChainId,
                    bridgeBatch.threshold,
                    bridgeBatch.isRollback
                )
            )
        );

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signature, bitmap);

        if (block.number > bridgeBatch.threshold && !bridgeBatch.isRollback) {
            revert("the batch has timed out");
        }

        uint256 length = bridgeBatch.messages.length;
        if (!bridgeBatch.isRollback) {
            for (uint256 i = 0; i < length; ) {
                _executeBridgeMessage(bridgeBatch.messages[i]);

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < length; ) {
                _executeRollbackBridgeMessage(bridgeBatch.messages[i]);

                unchecked {
                    ++i;
                }
            }
        }

        // slither-disable-next-line reentrancy-events
        emit BridgeBatchResult(
            bridgeBatch.messages[0].id,
            bridgeBatch.messages[bridgeBatch.messages.length - 1].id,
            bridgeBatch.sourceChainId,
            bridgeBatch.destinationChainId,
            bridgeBatch.isRollback
        );
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    // slither-disable-start dead-code
    function _verifyBatch(BridgeMessage[] calldata batch) private view {
        require(batch.length > 0, "EMPTY_BATCH");

        uint256 destinationChainId = block.chainid;
        uint256 sourceChainId = batch[0].sourceChainId;

        for (uint256 i = 0; i < batch.length; ) {
            BridgeMessage memory message = batch[i];
            require(message.sourceChainId == sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
            unchecked {
                ++i;
            }
        }
    }

    // slither-disable-end dead-code

    function _verifyRollbackBatch(BridgeMessage[] calldata batch) internal view {
        require(batch.length > 0, "EMPTY_BATCH");

        uint256 sourceChainId = block.chainid;
        uint256 destinationChainId = batch[0].destinationChainId;

        for (uint256 i = 0; i < batch.length; ) {
            BridgeMessage memory message = batch[i];
            require(message.sourceChainId == sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
            unchecked {
                ++i;
            }
        }
    }

    // slither-disable-start dead-code
    function _executeBridgeMessage(BridgeMessage calldata message) private {
        require(!processedEvents[message.id], "DestinationGateway: BRIDGE_MESSAGE_IS_ALREADY_PROCESSED");
        // revert transaction if client has added flag, or receiver has no code
        require(message.receiver.code.length != 0, "receiver has no code");

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
        // if bridge message fails, revert
        require(success, "Gateway: BATCH_ROLLBACK");

        // emit a ResultEvent indicating whether invocation of bridge message was successful
        // slither-disable-next-line reentrancy-events
        emit BridgeMessageResult(message.id, success, message.sourceChainId, message.destinationChainId, returnData);
    }

    // slither-disable-end dead-code

    function _executeRollbackBridgeMessage(BridgeMessage calldata message) internal {
        require(
            !processedEventsRollback[message.id],
            "DestinationGateway: ROLLBACK_BRIDGE_MESSAGE_IS_ALREADY_PROCESSED"
        );

        processedEventsRollback[message.id] = true;

        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-no-eth
        (bool success, bytes memory returnData) = message.receiver.call(
            abi.encodeWithSignature(
                "onStateRollback(uint256,address,bytes)",
                message.id,
                message.sender,
                message.payload
            )
        );

        // emit a ResultEvent indicating whether invocation of bridge rollback message was successful or not
        // slither-disable-next-line reentrancy-events
        emit BridgeMessageResult(message.id, success, message.sourceChainId, message.destinationChainId, returnData);
    }

    /**
     * @notice Returns all bridge messages in range [startId, endId]
     * @param startId Id of the 1st message in range
     * @param endId Id of the last message in range
     */
    function getMessagesInRange(uint256 startId, uint256 endId) external view returns (BridgeMessage[] memory) {
        require(startId > 0, "start id must be higher than 0");
        require(startId <= endId, "startId can not be bigger than end id");
        require(endId <= counter, "endId can not be bigger than length of bridge message array");

        BridgeMessage[] memory desiredMessages = new BridgeMessage[](endId - startId + 1);

        for (uint256 i = startId; i <= endId; i++) {
            desiredMessages[i - startId] = bridgeMessages[i];
        }

        return desiredMessages;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
