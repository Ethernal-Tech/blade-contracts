// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Gateway.sol";

contract TestRollbackGateway is Gateway {
    /**
     * @notice Test function to generate error for testing rollback
     * @param message Error message
     */
    error TestRollbackError(string message);

    /**
     * @notice receives the batch of messages and executes them
     * @param signedBatch batch of messages
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(SignedBridgeMessageBatch calldata signedBatch) external override {
        if (!signedBatch.batch.isRollback) {
            revert TestRollbackError("TESTING BATCH");
        }

        _verifyRollbackBatch(signedBatch.batch.messages);

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    signedBatch.batch.messages,
                    signedBatch.batch.sourceChainId,
                    signedBatch.batch.destinationChainId,
                    signedBatch.batch.threshold,
                    signedBatch.batch.isRollback
                )
            )
        );

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signedBatch.signature, signedBatch.bitmap);

        uint256 length = signedBatch.batch.messages.length;

        for (uint256 i = 0; i < length; ) {
            _executeRollbackBridgeMessage(signedBatch.batch.messages[i]);

            unchecked {
                ++i;
            }
        }

        // slither-disable-next-line reentrancy-events
        emit BridgeBatchResult(
            signedBatch.batch.messages[0].id,
            signedBatch.batch.messages[signedBatch.batch.messages.length].id,
            signedBatch.batch.sourceChainId,
            signedBatch.batch.destinationChainId,
            signedBatch.batch.isRollback
        );
    }
}
