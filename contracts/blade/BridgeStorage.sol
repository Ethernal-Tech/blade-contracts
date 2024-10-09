// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ValidatorSetStorage.sol";

contract BridgeStorage is ValidatorSetStorage {
    mapping(uint256 => SignedBridgeMessageBatch) public batches;
    mapping(uint256 => SignedValidatorSet) public commitedValidatorSets;
    mapping(uint256 => uint256) public lastCommitted;
    mapping(uint256 => uint256) public lastCommittedInternal;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public batchCounter;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public validatorSetCounter;

    event NewBatch(uint256 indexed id);
    event NewValidatorSetStored(uint256 indexed id);

    /**
     * @notice commits new validator set
     * @param newValidatorSet new validator set
     * @param signature aggregated signature of validators that signed the new validator set
     * @param bitmap bitmap of which validators signed the message
     */
    function commitValidatorSet(
        Validator[] calldata newValidatorSet,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) external override onlySystemCall {
        _commitValidatorSet(newValidatorSet, signature, bitmap);

        SignedValidatorSet storage signedValidatorSet = commitedValidatorSets[validatorSetCounter];
        signedValidatorSet.signature = signature;
        signedValidatorSet.bitmap = bitmap;

        for (uint256 i = 0; i < newValidatorSet.length; ) {
            signedValidatorSet.newValidatorSet[i] = newValidatorSet[i];
            unchecked {
                ++i;
            }
        }

        emit NewValidatorSetStored(validatorSetCounter);

        validatorSetCounter++;
    }

    /**
     * @notice commits new batch
     * @param batch new batch
     */
    function commitBatch(SignedBridgeMessageBatch calldata batch) external onlySystemCall {
        _verifyBatch(batch);

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(batch.rootHash, batch.startId, batch.endId, batch.sourceChainId, batch.destinationChainId)
            )
        );

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), batch.signature, batch.bitmap);

        batches[batchCounter] = batch;

        emit NewBatch(batchCounter);

        batchCounter++;
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    function _verifyBatch(SignedBridgeMessageBatch calldata batch) private {
        require(batch.rootHash == bytes32(0), "EMPTY_BATCH");

        if (batch.sourceChainId == block.chainid) {
            require(lastCommittedInternal[batch.destinationChainId] + 1 == batch.startId, "INVALID_LAST_COMMITTED");
            lastCommittedInternal[batch.destinationChainId] = batch.endId;
        } else {
            require(lastCommitted[batch.sourceChainId] + 1 == batch.startId, "INVALID_LAST_COMMITTED");
            lastCommitted[batch.sourceChainId] = batch.endId;
        }
    }

    /**
     * @notice Returns the committed batch based on provided id
     * @param id batch id
     */
    function getCommittedBatch(uint256 id) external view returns (SignedBridgeMessageBatch memory) {
        return batches[id];
    }

    /**
     * @notice Returns the committed validator set based on provided id
     * @param id validator set id
     */
    function getCommittedValidatorSet(uint256 id) external view returns (SignedValidatorSet memory) {
        return commitedValidatorSets[id];
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
