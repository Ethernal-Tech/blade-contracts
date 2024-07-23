// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {BridgeStorage} from "contracts/blade/BridgeStorage.sol";
import {Validator, BridgeMessage, BridgeMessageBatch} from "contracts/interfaces/blade/IBridgeGateway.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import {System} from "contracts/blade/System.sol";

abstract contract BridgeStorageTest is Test, System, BridgeStorage {
    BridgeStorage bridgeStorage;

    address public sender;
    address public receiver;
    Validator[] public validatorSet;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    BridgeMessage[] public msgs;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        bridgeStorage = new BridgeStorage();

        vm.startPrank(SYSTEM);

        sender = makeAddr("sender");
        receiver = makeAddr("receiver");

        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/forge/blade/generateMsgBridgeStorage.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        bytes memory out = vm.ffi(cmd);

        Validator[] memory validatorTemp;

        BridgeMessage[] memory messageTmp;

        (validatorTemp, aggMessagePoints, bitmaps, messageTmp) = abi.decode(
            out,
            (Validator[], uint256[2][], bytes[], BridgeMessage[])
        );

        for (uint256 i = 0; i < validatorTemp.length; i++) {
            validatorSet.push(validatorTemp[i]);
        }

        for (uint256 i = 0; i < messageTmp.length; i++) {
            msgs.push(messageTmp[i]);
        }
    }
}

abstract contract BridgeStorageInitialized is BridgeStorageTest {
    function setUp() public virtual override {
        super.setUp();
        bridgeStorage.initialize(bls, bn256G2, validatorSet);
    }
}

contract BridgeStorageUnitialized is BridgeStorageTest {
    function testInitialize() public {
        bridgeStorage.initialize(bls, bn256G2, validatorSet);

        assertEq(keccak256(abi.encode(bridgeStorage.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(bridgeStorage.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        for (uint256 i = 0; i < validatorSet.length; i++) {
            (address _address, uint256 votingPower) = bridgeStorage.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
        }
    }
}

contract BridgeStorageCommitBatchTests is BridgeStorageInitialized {
    function testCommitBatch_InvalidSignature() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({
            messages: msgs,
            sourceChainId: 2,
            destinationChainId: 3
        });

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        bridgeStorage.commitBatch(batch, aggMessagePoints[0], bitmaps[0]);
    }

    function testCommitBatch_EmptyBitmap() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({
            messages: msgs,
            sourceChainId: 2,
            destinationChainId: 3
        });

        vm.expectRevert("BITMAP_IS_EMPTY");
        bridgeStorage.commitBatch(batch, aggMessagePoints[1], bitmaps[1]);
    }

    function testCommitBatch_NotEnoughPower() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({
            messages: msgs,
            sourceChainId: 2,
            destinationChainId: 3
        });

        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        bridgeStorage.commitBatch(batch, aggMessagePoints[2], bitmaps[2]);
    }

    function testCommitBatch_Succes() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectEmit();
        emit NewBatch(0);
        console.logBytes(bitmaps[3]);
        bridgeStorage.commitBatch(batch, aggMessagePoints[3], bitmaps[3]);
    }
}
