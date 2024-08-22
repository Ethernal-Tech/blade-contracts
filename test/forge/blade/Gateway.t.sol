// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {Gateway} from "contracts/blade/Gateway.sol";
import {Validator, BridgeMessage, BridgeMessageBatch, DOMAIN_BRIDGE} from "contracts/interfaces/blade/IValidatorSetStorage.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import {System} from "contracts/blade/System.sol";

abstract contract GatewayTest is Test, System, Gateway {
    Gateway gateway;
    Validator[] public validatorSet;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    BridgeMessage[] public msgs;
    address receiver;
    bytes maxData;
    bytes moreThanMaxData;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        gateway = new Gateway();

        vm.chainId(3);

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

        for (uint256 i = 0; i < messageTmp.length; i++) {
            msgs.push(messageTmp[i]);
        }

        receiver = makeAddr("receiver");
        maxData = new bytes(gateway.MAX_LENGTH());
        moreThanMaxData = new bytes(gateway.MAX_LENGTH() + 1);
    }
}

abstract contract GatewayInitialized is GatewayTest {
    function setUp() public virtual override {
        super.setUp();
        gateway.initialize(bls, bn256G2, validatorSet);
    }
}

contract Uninitialized is GatewayTest {
    function testInitialize() public {
        gateway.initialize(bls, bn256G2, validatorSet);

        assertEq(keccak256(abi.encode(gateway.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(gateway.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        for (uint256 i = 0; i < validatorSet.length; i++) {
            (address _address, uint256 votingPower) = gateway.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
        }
    }
}

contract GatewayStateSyncTest is GatewayInitialized {
    function testConstructor() public {
        assertEq(gateway.counter(), 0);
    }

    function testCannotSyncState_InvalidReceiver() public {
        vm.expectRevert("INVALID_RECEIVER");
        gateway.sendBridgeMsg(address(0), "", 1);
    }

    function testCannotSyncState_ExceedsMaxLength() public {
        vm.expectRevert("EXCEEDS_MAX_LENGTH");
        gateway.sendBridgeMsg(receiver, moreThanMaxData, 1);
    }

     function testCannotSyncState_InvalidDestinationChainId() public {
        vm.expectRevert("EXCEEDS_MAX_LENGTH");
        gateway.sendBridgeMsg(receiver, moreThanMaxData, 0);
    }

    function testSyncState_EmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit BridgeMessageEvent(1, address(this), receiver, maxData);
        gateway.sendBridgeMsg(receiver, maxData);
    }

    function testSyncState_IncreasesCounter() public {
        gateway.sendBridgeMsg(receiver, maxData, 1);
        gateway.sendBridgeMsg(receiver, maxData, 1);
        vm.expectRevert("EXCEEDS_MAX_LENGTH");
        gateway.sendBridgeMsg(receiver, moreThanMaxData, 1);
        gateway.sendBridgeMsg(receiver, maxData, 1);
        vm.expectRevert("EXCEEDS_MAX_LENGTH");
        gateway.sendBridgeMsg(receiver, moreThanMaxData, 1);

        assertEq(gateway.counter(), 3);
    }
}

contract GatewayReceiveBatchTests is GatewayInitialized {
    function testReceiveBatch_InvalidSignature() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        gateway.receiveBatch(batch, aggMessagePoints[0], bitmaps[0]);
    }

    function testReceiveBatch_EmptyBitmap() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectRevert("BITMAP_IS_EMPTY");
        gateway.receiveBatch(batch, aggMessagePoints[1], bitmaps[1]);
    }

    function testReceiveBatch_NotEnoughPower() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        gateway.receiveBatch(batch, aggMessagePoints[2], bitmaps[2]);
    }

    function testReceiveBatch_Success() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectEmit();
        emit BridgeMessageResult(1, false, bytes(""));
        vm.expectEmit();
        emit BridgeMessageResult(2, false, bytes(""));
        gateway.receiveBatch(batch, aggMessagePoints[3], bitmaps[3]);
    }
}
