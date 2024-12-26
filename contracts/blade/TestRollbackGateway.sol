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
     * @param batchMessages batch of messages
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(
        BridgeMessage[] calldata batchMessages,
        SignedBridgeMessageBatch calldata signedBridgeBatch
    ) external override {
        if (!signedBridgeBatch.isRollback) {
            revert TestRollbackError("TESTING BATCH");
        }

        _verifyRollbackBatch(batchMessages);

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    calculateMerkleRoot(batchMessages),
                    signedBridgeBatch.startId,
                    signedBridgeBatch.endId,
                    signedBridgeBatch.sourceChainId,
                    signedBridgeBatch.destinationChainId,
                    signedBridgeBatch.threshold,
                    signedBridgeBatch.isRollback
                )
            )
        );

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signedBridgeBatch.signature, signedBridgeBatch.bitmap);

        uint256 length = batchMessages.length;

        for (uint256 i = 0; i < length; ) {
            _executeRollbackBridgeMessage(batchMessages[i]);

            unchecked {
                ++i;
            }
        }

        // slither-disable-next-line reentrancy-events
        emit BridgeBatchResult(
            signedBridgeBatch.startId,
            signedBridgeBatch.endId,
            signedBridgeBatch.sourceChainId,
            signedBridgeBatch.destinationChainId,
            signedBridgeBatch.isRollback
        );
    }
}
