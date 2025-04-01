// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

bytes32 constant DOMAIN_BRIDGE = keccak256("DOMAIN_BRIDGE");

/**
 * @param _address address of the validator
 * @param blsKey BLS public key
 * @param votingPower voting power of the validator
 */
struct Validator {
    address _address;
    uint256[4] blsKey;
    uint256 votingPower;
}

/**
 * @param id id of message
 * @param sourceChainId id of source chain
 * @param destinationChainId id of destination chain
 * @param sender sender account of this bridge message
 * @param receiver receiver account of this bridge message
 * @param payload payload
 */
struct BridgeMessage {
    uint256 id;
    uint256 sourceChainId;
    uint256 destinationChainId;
    address sender;
    address receiver;
    bool isRollback;
    bytes payload;
}

/**
 * @param messages list of all messages in batch
 * @param sourceChainId id of chain which is source of batch
 * @param destinationChainId id of chain which is destination of batch
 * @param threshold ock number before which the batch must be executed
 * @param isRollback flag for rollback batch
 * @param commitCounter number of commitments for this batch
 */
struct BridgeMessageBatch {
    BridgeMessage[] messages;
    uint256 sourceChainId;
    uint256 destinationChainId;
    uint256 threshold;
    uint256 numberOfRegularEvents;
    uint256 commitCounter;
}

/**
 * @param messages list of all messages in batch
 * @param sourceChainId id of source chain
 * @param destinationChainId id of destination chain
 * @param signature aggregated signature of validators that signed the batch
 * @param bitmap bitmap of which validators signed the message

 * @param validatorSetBatchId
 */
struct SignedBridgeMessageBatch {
    BridgeMessageBatch batch;
    uint256[2] signature;
    bytes bitmap;
    uint256 validatorSetBatchId;
}

/**
 * @param newValidatorSet new validator set
 * @param signature aggregated signature of validators that signed the new validator set
 * @param bitmap bitmap of which validators signed the message
 * @param blockMetadata metadata of the block
 */
struct SignedValidatorSet {
    Validator[] newValidatorSet;
    uint256[2] signature;
    bytes bitmap;
    BlockMetadata blockMetadata;
}

/**
 * @param blockHash hash of the block
 * @param blockRound round of the block
 * @param epochNumber epoch number of the block
 **/
struct BlockMetadata {
    bytes32 blockHash;
    uint256 blockRound;
    uint256 epochNumber;
}

interface IValidatorSetStorage {
    event NewValidatorSet(Validator[] newValidatorSet);

    /**
     * @notice commits new validator set
     * @param newValidatorSet new validator set
     * @param signature aggregated signature of validators that signed the new validator set
     * @param bitmap bitmap of which validators signed the message
     * @param blockMetadata metadata of the block
     */
    function commitValidatorSet(
        Validator[] calldata newValidatorSet,
        uint256[2] calldata signature,
        bytes calldata bitmap,
        BlockMetadata calldata blockMetadata
    ) external;
}
