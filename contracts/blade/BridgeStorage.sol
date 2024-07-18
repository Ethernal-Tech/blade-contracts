// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseBridgeGateway.sol";
import {System} from "./System.sol";

contract BridgeStorage is BaseBridgeGateway {
    mapping(uint256 => BridgeMessageBatch) public batches;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public batchCounter;

    event NewBatch(uint256 id);

    /**
     * @notice commits new batch
     * @param batch new batch
     */
    function commitBatch(BridgeMessageBatch calldata batch, uint256[2] calldata signature) external onlySystemCall {
        _verifyBatch(batch);

        bytes memory hash = abi.encode(keccak256(abi.encode(batch)));
        verifySignature(bls.hashToPoint(DOMAIN, hash), signature, batch.bitmap);

        batches[batchCounter++] = batch;

        emit NewBatch(batchCounter - 1);
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    function _verifyBatch(BridgeMessageBatch calldata batch) private pure {
        require(batch.messages.length > 0, "EMPTY_BATCH");

        uint256 sourceChainId = batch.messages[0].sourceChainId;
        uint256 destinationChainId = batch.messages[0].destinationChainId;
        for (uint256 i = 0; i < batch.messages.length; ++i) {
            BridgeMessage memory message = batch.messages[i];
            require(message.sourceChainId == sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
        }
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
