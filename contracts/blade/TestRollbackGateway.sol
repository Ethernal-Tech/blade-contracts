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
     * @param bridgeBatch batch of messages
     * @param signature the aggregated signature submitted by the proposer
     * @param bitmap bitmap of which validators signed the message
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(
        BridgeMessageBatch calldata bridgeBatch,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) external override {
        if (!bridgeBatch.isRollback) {
            revert TestRollbackError("TESTING BATCH");
        }

        _verifyRollbackBatch(bridgeBatch.messages);

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

        uint256 length = bridgeBatch.messages.length;

        for (uint256 i = 0; i < length; ) {
            _executeRollbackBridgeMessage(bridgeBatch.messages[i]);

            unchecked {
                ++i;
            }
        }

        // slither-disable-next-line reentrancy-events
        emit BridgeBatchResult(
            bridgeBatch.messages[0].id,
            bridgeBatch.messages[bridgeBatch.messages.length].id,
            bridgeBatch.sourceChainId,
            bridgeBatch.destinationChainId,
            bridgeBatch.isRollback
        );
    }
}
