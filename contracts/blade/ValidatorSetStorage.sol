// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {System} from "./System.sol";
import "../interfaces/common/IBLS.sol";
import "../interfaces/common/IBN256G2.sol";
import "../interfaces/blade/IValidatorSetStorage.sol";

contract ValidatorSetStorage is IValidatorSetStorage, Initializable, System {
    IBLS public bls;
    IBN256G2 public bn256G2;

    mapping(uint256 => SignedValidatorSet) committedValidatorSets;
    uint256 public validatorSetCounter;
    uint256 public currentValidatorSetLength;
    bytes32 public currentValidatorSetHash;
    uint256 public totalVotingPower;

    /**
     * @notice initializes the contract
     * @param newBls address of the BLS library contract
     * @param newBn256G2 address of the BN256G2 library contract
     * @param validators list of validators
     */
    function initialize(IBLS newBls, IBN256G2 newBn256G2, Validator[] calldata validators) public virtual initializer {
        bls = newBls;
        bn256G2 = newBn256G2;
        _setInitialValidatorSet(validators);
    }

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
    ) external virtual {
        _commitValidatorSet(newValidatorSet, signature, bitmap, blockMetadata);
    }

    /**
     * @notice Internal function that sets the new validator set
     * @param newValidatorSet new validator set
     */
    function _setInitialValidatorSet(Validator[] calldata newValidatorSet) internal {
        currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));
        uint256 totalPower = 0;

        SignedValidatorSet storage signedValidatorSet = committedValidatorSets[validatorSetCounter];
        for (uint256 i = 0; i < newValidatorSet.length; ) {
            signedValidatorSet.newValidatorSet.push(newValidatorSet[i]);
            uint256 votingPower = newValidatorSet[i].votingPower;
            require(votingPower > 0, "VOTING_POWER_ZERO");
            totalPower += votingPower;
            unchecked {
                ++i;
            }
        }

        totalVotingPower = totalPower;
    }

    /**
     * @notice Internal function that asserts that the signature is valid and that the required threshold is met
     * @param message The message that was signed by validators (i.e. checkpoint hash)
     * @param signature The aggregated signature submitted by the proposer
     * @param bitmap bitmap of which validators signed the message
     */
    function verifySignature(
        uint256[2] memory message,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) internal view {
        // slither-disable-next-line uninitialized-local
        uint256[4] memory aggPubkey;
        uint256 aggVotingPower = 0;
        for (uint256 i = 0; i < committedValidatorSets[validatorSetCounter].newValidatorSet.length; ) {
            if (_getValueFromBitmap(bitmap, i)) {
                if (aggVotingPower == 0) {
                    aggPubkey = committedValidatorSets[validatorSetCounter].newValidatorSet[i].blsKey;
                } else {
                    uint256[4] memory blsKey = committedValidatorSets[validatorSetCounter].newValidatorSet[i].blsKey;
                    // slither-disable-next-line calls-loop
                    (aggPubkey[0], aggPubkey[1], aggPubkey[2], aggPubkey[3]) = bn256G2.ecTwistAdd(
                        aggPubkey[0],
                        aggPubkey[1],
                        aggPubkey[2],
                        aggPubkey[3],
                        blsKey[0],
                        blsKey[1],
                        blsKey[2],
                        blsKey[3]
                    );
                }
                aggVotingPower += committedValidatorSets[validatorSetCounter].newValidatorSet[i].votingPower;
            }
            unchecked {
                ++i;
            }
        }

        require(aggVotingPower != 0, "BITMAP_IS_EMPTY");
        require(aggVotingPower > ((2 * totalVotingPower) / 3), "INSUFFICIENT_VOTING_POWER");

        (bool callSuccess, bool result) = bls.verifySingle(signature, aggPubkey, message);

        require(callSuccess && result, "SIGNATURE_VERIFICATION_FAILED");
    }

    /**
     * @notice Private function that gets the value of a bit in a bitmap
     * @param bitmap bitmap
     * @param index index of the bit
     */
    function _getValueFromBitmap(bytes calldata bitmap, uint256 index) private pure returns (bool) {
        uint256 byteNumber = index / 8;
        uint8 bitNumber = uint8(index % 8);

        if (byteNumber >= bitmap.length) {
            return false;
        }

        // Get the value of the bit at the given 'index' in a byte.
        return uint8(bitmap[byteNumber]) & (1 << bitNumber) > 0;
    }

    /**
     * @notice Commits a new validator set by verifying its signature and setting it in the storage.
     * @dev This function requires that the new validator set is non-empty and verifies its signature before updating the validator set.
     * @param newValidatorSet The array of validators to be set as the new validator set
     * @param signature The aggregated signature of the validators that signed the new validator set
     * @param bitmap The bitmap representing which validators signed the new validator set
     * @param blockMetadata The blockMetadata represents
     * Emits a `NewValidatorSet` event after successfully setting the new validator set.
     */
    function _commitValidatorSet(
        Validator[] calldata newValidatorSet,
        uint256[2] calldata signature,
        bytes calldata bitmap,
        BlockMetadata calldata blockMetadata
    ) internal {
        uint256 totalPower = 0;

        require(newValidatorSet.length > 0, "EMPTY_VALIDATOR_SET");

        bytes memory hash = abi.encode(keccak256(abi.encode(blockMetadata)));

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signature, bitmap);

        validatorSetCounter++;

        currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));

        SignedValidatorSet storage signedValidatorSet = committedValidatorSets[validatorSetCounter];
        signedValidatorSet.signature = signature;
        signedValidatorSet.bitmap = bitmap;
        signedValidatorSet.blockMetadata = blockMetadata;
        uint256 length = newValidatorSet.length;
        for (uint256 i = 0; i < length; ) {
            signedValidatorSet.newValidatorSet.push(newValidatorSet[i]);
            uint256 votingPower = newValidatorSet[i].votingPower;
            require(votingPower > 0, "VOTING_POWER_ZERO");
            totalPower += votingPower;
            unchecked {
                ++i;
            }
        }

        totalVotingPower = totalPower;

        emit NewValidatorSet(newValidatorSet);
    }
}
