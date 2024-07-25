// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

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
