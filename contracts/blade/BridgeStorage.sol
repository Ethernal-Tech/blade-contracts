// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ValidatorSetStorage.sol";

contract BridgeStorage is ValidatorSetStorage {
    uint256 public validatorSetCounter;
    address[] public addresses;

    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => SignedBridgeMessageBatch) public batches;
    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => SignedValidatorSet) public commitedValidatorSets;
    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => uint256) public lastCommittedE2I;
    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => uint256) public lastCommittedI2E;
    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => uint256[]) public rollbackedE2I;
    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => uint256[]) public rollbackedI2E;
    /// @custom:security write-protection="onlySystemCall()"
    mapping(bytes => uint256) public batchCommitCounter;
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
    function initializeBS(
        IBLS newBls,
        IBN256G2 newBn256G2,
        Validator[] calldata validators,
        address[] calldata addressesGateway
    ) public initializer {
        _init(newBls, newBn256G2, validators);
        validatorSetCounter = 1;
        addresses = addressesGateway;
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

        SignedValidatorSet storage signedValidatorSet = commitedValidatorSets[validatorSetCounter];
        signedValidatorSet.signature = signature;
        signedValidatorSet.bitmap = bitmap;
        signedValidatorSet.blockMetadata = blockMetadata;

        uint256 length = newValidatorSet.length;
        for (uint256 i = 0; i < length; ) {
            signedValidatorSet.newValidatorSet.push(newValidatorSet[i]);
            unchecked {
                ++i;
            }
        }

        _insertNewValidatorSetBatchRef();

        validatorSetCounter++;

        length = addresses.length;
        // slither-disable-start calls-loop,reentrancy-events,low-level-calls
        for (uint i = 0; i < length; ) {
            (bool ok, ) = addresses[i].call(
                abi.encodeWithSignature(
                    "commitValidatorSet((address,uint256[4],uint256)[],uint256[2],bytes,(bytes32,uint256,uint256))",
                    newValidatorSet,
                    signature,
                    bitmap,
                    blockMetadata
                )
            );

            require(ok, "cannot commit new validator set");
            unchecked {
                ++i;
            }
        }
        // slither-disable-end calls-loop,reentrancy-events,low-level-calls

        emit NewValidatorSetStored(validatorSetCounter);
    }

    /**
     * @notice commits new batch
     * @param signedBatch new batch with signature and bitmap
     */
    function commitBatch(SignedBridgeMessageBatch calldata signedBatch) external onlySystemCall {
        _verifyBatch(signedBatch.batch);

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

        _verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signedBatch.signature, signedBatch.bitmap);

        bytes memory batchHash = abi.encode(
            keccak256(
                abi.encode(
                    signedBatch.batch.messages,
                    signedBatch.batch.sourceChainId,
                    signedBatch.batch.destinationChainId,
                    0,
                    0,
                    0
                )
            )
        );

        require(signedBatch.batch.commitCounter > batchCommitCounter[batchHash], "batch is already committed");

        batchCommitCounter[batchHash]++;

        SignedBridgeMessageBatch storage batch = batches[batchCounter];
        batch.batch = signedBatch.batch;
        batch.signature = signedBatch.signature;
        batch.bitmap = signedBatch.bitmap;

        emit NewBatch(batchCounter);

        batchCounter++;
    }

    /**
     * @notice Internal function that verifies the regular batch
     * @param batch batch to verify
     */
    function _verifyBatch(BridgeMessageBatch calldata batch) private {
        require(batch.messages.length > 0, "EMPTY_BATCH");
        require(
            batch.numberOfRegularEvents <= batch.messages.length,
            "NUMBER_OF_EVENTS_IS_GREATER_THAN_MESSAGE_LENGTH"
        );

        for (uint256 i = 0; i < batch.messages.length; ) {
            BridgeMessage memory message = batch.messages[i];
            require(message.sourceChainId == batch.sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == batch.destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
            unchecked {
                ++i;
            }

            if (message.isRollback) {
                if (message.sourceChainId == block.chainid) {
                    rollbackedI2E[message.destinationChainId].push(message.id);
                } else {
                    rollbackedE2I[message.sourceChainId].push(message.id);
                }
            }
        }
        if (batch.numberOfRegularEvents > 0) {
            if (batch.sourceChainId == block.chainid) {
                require(
                    lastCommittedI2E[batch.destinationChainId] + 1 == batch.messages[0].id,
                    "INVALID_LAST_COMMITTED"
                );
                lastCommittedI2E[batch.destinationChainId] = batch.messages[batch.numberOfRegularEvents - 1].id;
            } else {
                require(lastCommittedE2I[batch.sourceChainId] + 1 == batch.messages[0].id, "INVALID_LAST_COMMITTED");
                lastCommittedE2I[batch.sourceChainId] = batch.messages[batch.numberOfRegularEvents - 1].id;
            }
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
        return commitedValidatorSets[id];
    }

    /**
     * @notice Inserts an empty batch used as a reference for each committed validator set batch
     */
    function _insertNewValidatorSetBatchRef() private {
        SignedBridgeMessageBatch storage newValidatorSetBatchRef = batches[batchCounter];
        newValidatorSetBatchRef.validatorSetBatchId = validatorSetCounter;
        batchCounter++;
    }

    /**
     * @notice Returns true if message with id is rollbacked on I2E transfer, else false
     * @param chainId external chain id
     * @param id message id
     */
    function getConfirmedRollbackedI2E(uint256 chainId, uint256 id) external view returns (bool) {
        uint256[] storage rollbacked = rollbackedI2E[chainId];
        for (uint256 i = 0; i < rollbacked.length; i++) {
            if (rollbacked[i] == id) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Returns true if message with id is rollbacked on E2I transfer, else false
     * @param chainId external chain id
     * @param id message id
     */
    function getConfirmedRollbackedE2I(uint256 chainId, uint256 id) external view returns (bool) {
        uint256[] storage rollbacked = rollbackedE2I[chainId];
        for (uint256 i = 0; i < rollbacked.length; i++) {
            if (rollbacked[i] == id) {
                return true;
            }
        }

        return false;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
