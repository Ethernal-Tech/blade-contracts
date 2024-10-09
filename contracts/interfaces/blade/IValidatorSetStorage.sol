// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

bytes32 constant DOMAIN_VALIDATOR_SET = keccak256("DOMAIN_VALIDATOR_SET");

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
    bytes payload;
}

/**
 * @param rootHash root hash of the batch
 * @param startId start id of the batch
 * @param endId end id of the batch
 * @param sourceChainId id of source chain
 * @param destinationChainId id of destination chain
 * @param signature aggregated signature of validators that signed the batch
 * @param bitmap bitmap of which validators signed the message
 */
struct SignedBridgeMessageBatch {
    bytes32 rootHash;
    uint256 startId;
    uint256 endId;
    uint256 sourceChainId;
    uint256 destinationChainId;
    uint256[2] signature;
    bytes bitmap;
}

/**
 * @param newValidatorSet new validator set
 * @param signature aggregated signature of validators that signed the new validator set
 * @param bitmap bitmap of which validators signed the message
 */
struct SignedValidatorSet {
    Validator[] newValidatorSet;
    uint256[2] signature;
    bytes bitmap;
}

interface IValidatorSetStorage {
    event NewValidatorSet(Validator[] newValidatorSet);

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
    ) external;
}
