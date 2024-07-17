// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {BridgeStorage} from "contracts/blade/BridgeStorage.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import {System} from "contracts/blade/System.sol";

abstract contract BridgeStorageTest is Test, System, BridgeStorage{
    BridgeStorage bridgeStorage;
    uint256 validatorSetSize;

    address public sender;
    address public receiver;
    BridgeStorage.Validator[] public validatorSet;
    bytes32[] public hashes;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    uint256[] public aggVotingPowers;
    BridgeStorage.BridgeMessage[] msgs;

    function setUp() public virtual{
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

        BridgeStorage.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, bitmaps, aggVotingPowers) = abi.decode(
            out,
            (uint256, BridgeStorage.Validator[], uint256[2][], bytes32[], bytes[], uint256[])
        );

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }
    }
}

abstract contract BridgeStorageInitialized is BridgeStorageTest{
    function setUp() public virtual override{
        super.setUp();
        bridgeStorage.initialize(bls, bn256G2, validatorSet);
    }
}

abstract contract BridgeStorageWithMessages is BridgeStorageInitialized{
    function setUp() public virtual override{
        super.setUp();
        
        BridgeStorage.BridgeMessage memory firstMessage = BridgeStorage.BridgeMessage({
            id:0,
            sourceChainId:100,
            destinationChainId:2,
            sender:sender,
            receiver: receiver,
            payload: bytes("0")
        });

        msgs.push(firstMessage);
    }
}

contract BridgeStorageUnitialized is BridgeStorageTest{
    function testInitialize() public{
        bridgeStorage.initialize(bls, bn256G2, validatorSet);

        assertEq(keccak256(abi.encode(bridgeStorage.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(bridgeStorage.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        assertEq(bridgeStorage.currentValidatorSetLength(), validatorSetSize);
        for (uint256 i = 0; i < validatorSetSize; i++) {
            (address _address, uint256 votingPower) = bridgeStorage.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
        }
    }
}

contract BridgeStorageCommitBatchTests is BridgeStorageWithMessages{
    function testCommitBatch_InvalidSignature() public{
        BridgeStorage.BridgeMessageBatch memory batch = BridgeStorage.BridgeMessageBatch({
            messages: msgs,
            signature: aggMessagePoints[0],
            bitmap: bitmaps[0]
        });

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        bridgeStorage.commitBatch(batch);
    }

    function testCommitBatch_EmptyBitmap() public{
        BridgeStorage.BridgeMessageBatch memory batch = BridgeStorage.BridgeMessageBatch({
            messages: msgs,
            signature: aggMessagePoints[1],
            bitmap: bitmaps[1]
        });

        vm.expectRevert("BITMAP_IS_EMPTY");
        bridgeStorage.commitBatch(batch);
    }

    function testCommitBatch_NotEnoughPower() public{
        BridgeStorage.BridgeMessageBatch memory batch = BridgeStorage.BridgeMessageBatch({
            messages: msgs,
            signature: aggMessagePoints[2],
            bitmap: bitmaps[2]
        });

        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        bridgeStorage.commitBatch(batch);
    }



    function testCommitBatch_Succes() public{
        BridgeStorage.BridgeMessageBatch memory batch = BridgeStorage.BridgeMessageBatch({
            messages: msgs,
            signature: aggMessagePoints[3],
            bitmap: bitmaps[3]
        });

        vm.expectEmit();
        emit NewBatch(0);
        bridgeStorage.commitBatch(batch);
    } 
}




