// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@utils/Test.sol";
import {BridgeStorage} from "contracts/blade/BridgeStorage.sol";
import {Validator, BridgeMessage, SignedBridgeMessageBatch, DOMAIN_BRIDGE} from "contracts/interfaces/blade/IValidatorSetStorage.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import {System} from "contracts/blade/System.sol";
import "contracts/lib/Merkle.sol";

abstract contract BridgeStorageTest is Test, System, BridgeStorage {
    BridgeStorage bridgeStorage;

    address public sender;
    address public receiver;
    Validator[] public validatorSet;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    BridgeMessage[] public msgs;
    bytes32 rootHash;

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
        cmd[3] = vm.toString(abi.encode(DOMAIN_BRIDGE));
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

        bytes32[] memory leaves = new bytes32[](messageTmp.length);
        for (uint256 i = 0; i < messageTmp.length; i++) {
            msgs.push(messageTmp[i]);
            leaves[i] = keccak256(
                abi.encode(
                    messageTmp[i].id,
                    messageTmp[i].sourceChainId,
                    messageTmp[i].destinationChainId,
                    messageTmp[i].sender,
                    messageTmp[i].receiver,
                    messageTmp[i].payload
                )
            );
        }

        rootHash = Merkle.computeMerkleRoot(leaves);
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
        SignedBridgeMessageBatch memory batch = SignedBridgeMessageBatch({
            rootHash: rootHash,
            startId: msgs[0].id,
            endId: msgs[msgs.length - 1].id,
            sourceChainId: 2,
            destinationChainId: 3,
            signature: aggMessagePoints[0],
            bitmap: bitmaps[0]
        });

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        bridgeStorage.commitBatch(batch);
    }

    function testCommitBatch_EmptyBitmap() public {
        SignedBridgeMessageBatch memory batch = SignedBridgeMessageBatch({
            rootHash: rootHash,
            startId: msgs[0].id,
            endId: msgs[msgs.length - 1].id,
            sourceChainId: 2,
            destinationChainId: 3,
            signature: aggMessagePoints[1],
            bitmap: bitmaps[1]
        });

        vm.expectRevert("BITMAP_IS_EMPTY");
        bridgeStorage.commitBatch(batch);
    }

    function testCommitBatch_NotEnoughPower() public {
        SignedBridgeMessageBatch memory batch = SignedBridgeMessageBatch({
            rootHash: rootHash,
            startId: msgs[0].id,
            endId: msgs[msgs.length - 1].id,
            sourceChainId: 2,
            destinationChainId: 3,
            signature: aggMessagePoints[2],
            bitmap: bitmaps[2]
        });

        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        bridgeStorage.commitBatch(batch);
    }

    function testCommitBatch_Success() public {
        SignedBridgeMessageBatch memory batch = SignedBridgeMessageBatch({
            rootHash: rootHash,
            startId: msgs[0].id,
            endId: msgs[msgs.length - 1].id,
            sourceChainId: 2,
            destinationChainId: 3,
            signature: aggMessagePoints[3],
            bitmap: bitmaps[3]
        });

        vm.expectEmit();
        emit NewBatch(0);
        bridgeStorage.commitBatch(batch);
    }
}
