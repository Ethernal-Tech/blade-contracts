// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ValidatorSetStorage.sol";

contract BridgeStorage is ValidatorSetStorage {
    mapping(uint256 => SignedBridgeMessageBatch) public batches;
    mapping(uint256 => uint256) public lastCommitted;
    mapping(uint256 => uint256) public lastCommittedInternal;
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public batchCounter;

    event NewBatch(uint256 indexed id);
    event NewValidatorSetStored(uint256 indexed id);

    /**
     * @notice initializes the contract
     * @param newBls address of the BLS library contract
     * @param newBn256G2 address of the BN256G2 library contract
     * @param validators list of validators
     */
    function initialize(IBLS newBls, IBN256G2 newBn256G2, Validator[] calldata validators) public override initializer {
        bls = newBls;
        bn256G2 = newBn256G2;
        _setInitialValidatorSet(validators);
    }

    /**
     * @notice commits new validator set
     * @param newValidatorSet new validator set
     * @param signature aggregated signature of validators that signed the new validator set
     * @param bitmap bitmap of which validators signed the message
     */
    function commitValidatorSet(
        Validator[] calldata newValidatorSet,
        uint256[2] calldata signature,
        bytes calldata bitmap,
        BlockMetadata calldata blockMetadata
    ) external override onlySystemCall {
        _commitValidatorSet(newValidatorSet, signature, bitmap, blockMetadata);

        _insertNewValidatorSetBatchRef();

        emit NewValidatorSetStored(validatorSetCounter);
    }

    /**
     * @notice commits new batch
     * @param batch new batch
     */
    function commitBatch(SignedBridgeMessageBatch calldata batch) external onlySystemCall {
        if (batch.isRollback) {
            _verifyRollbackBatch(batch);
        } else {
            _verifyRegularBatch(batch);
        }

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    batch.rootHash,
                    batch.startId,
                    batch.endId,
                    batch.sourceChainId,
                    batch.destinationChainId,
                    batch.threshold,
                    batch.isRollback
                )
            )
        );

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), batch.signature, batch.bitmap);

        batches[batchCounter] = batch;

        emit NewBatch(batchCounter);

        batchCounter++;
    }

    /**
     * @notice Internal function that verifies the regular batch
     * @param batch batch to verify
     */
    function _verifyRegularBatch(SignedBridgeMessageBatch calldata batch) private {
        require(batch.rootHash != bytes32(0), "EMPTY_BATCH");
        require(batch.sourceChainId != batch.destinationChainId, "sourceChainId and destinationChainId not equal");
        if (batch.sourceChainId == block.chainid) {
            require(lastCommittedInternal[batch.destinationChainId] + 1 == batch.startId, "INVALID_LAST_COMMITTED");
            lastCommittedInternal[batch.destinationChainId] = batch.endId;
        } else {
            require(lastCommitted[batch.sourceChainId] + 1 == batch.startId, "INVALID_LAST_COMMITTED");
            lastCommitted[batch.sourceChainId] = batch.endId;
        }
    }

    /**
     * @notice Internal function that verifies the rollback batch
     * @param batch batch to verify
     */
    function _verifyRollbackBatch(SignedBridgeMessageBatch calldata batch) private pure {
        require(batch.rootHash != bytes32(0), "EMPTY_BATCH");
        require(batch.sourceChainId != batch.destinationChainId, "sourceChainId and destinationChainId not equal");
    }

    /**
     * @notice Returns the committed batch based on provided id
     * @param id batch id
     */
    function getCommittedBatch(uint256 id) external view returns (SignedBridgeMessageBatch memory) {
        return batches[id];
    }

    /**
     * @notice Returns all committed batches from the provided ID to the end of the array
     * @param firstBatchNumber batch id
     */
    function getCommittedBatches(uint256 firstBatchNumber) external view returns (SignedBridgeMessageBatch[] memory) {
        SignedBridgeMessageBatch[] memory unexecutedBatches = new SignedBridgeMessageBatch[](
            batchCounter - firstBatchNumber
        );

        for (uint256 i = firstBatchNumber; i < batchCounter; i++) {
            unexecutedBatches[i - firstBatchNumber] = batches[i];
        }

        return unexecutedBatches;
    }

    /**
     * @notice Returns the committed validator set based on provided id
     * @param id validator set id
     */
    function getCommittedValidatorSet(uint256 id) external view returns (SignedValidatorSet memory) {
        return committedValidatorSets[id];
    }

    /**
     * @notice Inserts an empty batch used as a reference for each committed validator set batch
     */
    function _insertNewValidatorSetBatchRef() private {
        SignedBridgeMessageBatch storage newValidatorSetBatchRef = batches[batchCounter];
        newValidatorSetBatchRef.validatorSetBatchId = validatorSetCounter;
        batchCounter++;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
