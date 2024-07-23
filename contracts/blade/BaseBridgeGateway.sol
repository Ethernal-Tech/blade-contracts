// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {System} from "./System.sol";
import "../interfaces/common/IBLS.sol";
import "../interfaces/common/IBN256G2.sol";
import "../interfaces/blade/IBridgeGateway.sol";

contract BaseBridgeGateway is IBridgeGateway, Initializable, System {
    bytes32 public constant DOMAIN = keccak256("DOMAIN_BRIDGE");

    IBLS public bls;
    IBN256G2 public bn256G2;

    mapping(uint256 => Validator) public currentValidatorSet;
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
        _setNewValidatorSet(validators);
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
        bytes calldata bitmap
    ) external onlySystemCall {
        require(newValidatorSet.length > 0, "EMPTY_VALIDATOR_SET");

        bytes memory hash = abi.encode(keccak256(abi.encode(newValidatorSet)));

        verifySignature(bls.hashToPoint(DOMAIN, hash), signature, bitmap);

        _setNewValidatorSet(newValidatorSet);

        emit NewValidatorSet(newValidatorSet);
    }

    /**
     * @notice Internal function that sets the new validator set
     * @param newValidatorSet new validator set
     */
    function _setNewValidatorSet(Validator[] calldata newValidatorSet) private {
        uint256 length = newValidatorSet.length;
        currentValidatorSetLength = length;
        currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));
        uint256 totalPower = 0;
        for (uint256 i = 0; i < length; ) {
            uint256 votingPower = newValidatorSet[i].votingPower;
            require(votingPower > 0, "VOTING_POWER_ZERO");
            totalPower += votingPower;
            currentValidatorSet[i] = newValidatorSet[i];
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
        uint256 length = currentValidatorSetLength;
        // slither-disable-next-line uninitialized-local
        uint256[4] memory aggPubkey;
        uint256 aggVotingPower = 0;
        for (uint256 i = 0; i < length; ) {
            if (_getValueFromBitmap(bitmap, i)) {
                if (aggVotingPower == 0) {
                    aggPubkey = currentValidatorSet[i].blsKey;
                } else {
                    uint256[4] memory blsKey = currentValidatorSet[i].blsKey;
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
                aggVotingPower += currentValidatorSet[i].votingPower;
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
     * @notice Internal function that gets the value of a bit in a bitmap
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
}