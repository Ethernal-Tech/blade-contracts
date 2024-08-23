// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ValidatorSetStorage.sol";

contract BridgeStorage is ValidatorSetStorage {
    mapping(uint256 => BridgeMessageBatch) public batches;
    mapping(uint256 => uint256) public lastCommitted;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public batchCounter;

    event NewBatch(uint256 id);

    /**
     * @notice commits new batch
     * @param batch new batch
     */
    function commitBatch(
        BridgeMessageBatch calldata batch,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) external onlySystemCall {
        _verifyBatch(batch);

        bytes memory hash = abi.encode(keccak256(abi.encode(batch)));
        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signature, bitmap);

        batches[batchCounter++] = batch;

        emit NewBatch(batchCounter - 1);
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    function _verifyBatch(BridgeMessageBatch calldata batch) private {
        require(batch.messages.length > 0, "EMPTY_BATCH");
        require(lastCommitted[batch.destinationChainId] + 1 == batch.messages[0].id, "INVALID_LAST_COMMITTED");

        for (uint256 i = 0; i < batch.messages.length; ) {
            BridgeMessage memory message = batch.messages[i];
            require(message.sourceChainId == batch.sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == batch.destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
            unchecked {
                ++i;
            }
        }

        lastCommitted[batch.destinationChainId] = batch.messages[batch.messages.length - 1].id;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
