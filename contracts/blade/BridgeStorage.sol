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
    function commitBatch(BridgeMessageBatch calldata batch) external onlySystemCall {
        verifyBatch(batch);

        bytes memory hash = abi.encode(keccak256(abi.encode(batch)));
        verifySignature(bls.hashToPoint(DOMAIN, hash), batch.signature, batch.bitmap);

        batches[batchCounter++] = batch;

        emit NewBatch(batchCounter - 1);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
