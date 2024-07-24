// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseBridgeGateway.sol";

contract DestinationGateway is BaseBridgeGateway {
    /// @custom:security write-protection="onlySystemCall()"
    // slither-disable-next-line protected-variables
    mapping(uint256 => bool) public processedEvents;

    event BridgeMessageResult(uint256 indexed counter, bool indexed status, bytes message);

    /**
     * @notice receives the batch of messages and executes them
     * @param batch batch of messages
     * @param signature the aggregated signature submitted by the proposer
     * @param bitmap bitmap of which validators signed the message
     */
    // slither-disable-next-line protected-variables
    function receiveBatch(
        BridgeMessageBatch calldata batch,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) external {
        _verifyBatch(batch);

        bytes memory hash = abi.encode(keccak256(abi.encode(batch)));
        verifySignature(bls.hashToPoint(DOMAIN, hash), signature, bitmap);

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
        require(!processedEvents[message.id], "DestinationGateway: BRIDGE_MESSAGE_IS_PROCESSED");
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
