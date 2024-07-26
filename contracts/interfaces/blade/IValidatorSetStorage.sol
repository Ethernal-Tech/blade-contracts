// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
 * @param messages list of all messages in batch
 * @param sourceChainId id of chain which is source of batch
 * @param destinationChainId id of chain which is destination of batch
 */
struct BridgeMessageBatch {
    BridgeMessage[] messages;
    uint256 sourceChainId;
    uint256 destinationChainId;
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
