// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Gateway.sol";

contract TestRollbackGateway is Gateway {
    /**
     * @notice receives the batch of messages and executes them
     * @param signedBatch batch of messages
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(SignedBridgeMessageBatch calldata signedBatch) external override {
        _verifyBatch(signedBatch.batch.messages);

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    signedBatch.batch.messages,
                    signedBatch.batch.sourceChainId,
                    signedBatch.batch.destinationChainId,
                    signedBatch.batch.threshold,
                    signedBatch.batch.numberOfRegularEvents,
                    signedBatch.batch.commitCounter
                )
            )
        );

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signedBatch.signature, signedBatch.bitmap);

        uint256 length = signedBatch.batch.messages.length;

        for (uint256 i = 0; i < length; ) {
            BridgeMessage calldata message = signedBatch.batch.messages[i];
            if (!message.isRollback) {
                processedEvents[message.id] = true;

                emit BridgeMessageResult(
                    message.id,
                    false,
                    message.sourceChainId,
                    message.destinationChainId,
                    message.isRollback,
                    "rollback"
                );
            }

            unchecked {
                ++i;
            }
        }

        // slither-disable-next-line reentrancy-events
        emit BridgeBatchProcessed(true, signedBatch.batch.sourceChainId, signedBatch.batch.destinationChainId, hash);
    }
}
