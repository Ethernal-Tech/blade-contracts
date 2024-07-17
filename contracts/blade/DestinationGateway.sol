// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseBridgeGateway.sol";

contract DestinationGateway is BaseBridgeGateway {
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public lastCommittedId;

    /**
     * @notice receives the batch of messages and executes them
     * @param batch batch of messages
     */
    function receive(BridgeMessageBatch calldata batch) public {
        verifyBatch(batch);
        
        bytes memory hash = abi.encode(keccak256(abi.encode(batch)));
        verifySignature(bls.hashToPoint(DOMAIN, hash), batch.signature, batch.bitmap);
    }
}