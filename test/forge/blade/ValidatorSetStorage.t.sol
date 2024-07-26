// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {ValidatorSetStorage} from "contracts/blade/ValidatorSetStorage.sol";
import {Validator, DOMAIN_VALIDATOR_SET} from "contracts/interfaces/blade/IValidatorSetStorage.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import {System} from "contracts/blade/System.sol";

abstract contract ValidatorSetStorageTest is Test, System, ValidatorSetStorage {
    uint256 validatorSetSize;
    bytes32[] hashes;

    uint256[] aggVotingPowers;
    ValidatorSetStorage validatorSetStorage;
    Validator[] public validatorSet;

    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        validatorSetStorage = new ValidatorSetStorage();

        vm.startPrank(SYSTEM);

        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/blade/generateMsgValidatorSetStorage.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN_VALIDATOR_SET));
        bytes memory out = vm.ffi(cmd);

        Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, bitmaps, aggVotingPowers) = abi.decode(
            out,
            (uint256, Validator[], uint256[2][], bytes32[], bytes[], uint256[])
        );

        for (uint256 i = 0; i < validatorSetTmp.length; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }
    }
}

abstract contract BaseBridgeGatewayInitialized is ValidatorSetStorageTest {
    function setUp() public virtual override {
        super.setUp();
        validatorSetStorage.initialize(bls, bn256G2, validatorSet);
    }
}

contract BaseBridgeCommitValidatorSetTests is BaseBridgeGatewayInitialized {
    function testCommitValidatorSet_InvalidSignature() public {
        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        validatorSetStorage.commitValidatorSet(validatorSet, aggMessagePoints[0], bitmaps[0]);
    }

    function testCommitValidatorSet_EmptyBitmap() public {
        vm.expectRevert("BITMAP_IS_EMPTY");
        validatorSetStorage.commitValidatorSet(validatorSet, aggMessagePoints[1], bitmaps[1]);
    }

    function testCommitValidatorSet_NotEnoughPower() public {
        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        validatorSetStorage.commitValidatorSet(validatorSet, aggMessagePoints[2], bitmaps[2]);
    }

    function testCommitValidatorSet_Success() public {
        vm.expectEmit();
        emit NewValidatorSet(validatorSet);
        validatorSetStorage.commitValidatorSet(validatorSet, aggMessagePoints[3], bitmaps[3]);
    }
}
