// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {DestinationGateway} from "contracts/blade/DestinationGateway.sol";
import {Validator, BridgeMessage, BridgeMessageBatch, DOMAIN_BRIDGE} from "contracts/interfaces/blade/IValidatorSetStorage.sol";
import {BLS} from "contracts/common/BLS.sol";
import {BN256G2} from "contracts/common/BN256G2.sol";
import {System} from "contracts/blade/System.sol";

abstract contract DestinationGatewayTest is Test, System, DestinationGateway {
    DestinationGateway destinationGateway;

    address public sender;
    address public receiver;
    Validator[] public validatorSet;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    BridgeMessage[] public msgs;

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        destinationGateway = new DestinationGateway();

        vm.chainId(3);

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

        for (uint256 i = 0; i < messageTmp.length; i++) {
            msgs.push(messageTmp[i]);
        }
    }
}

abstract contract DestinationGatewayInitialized is DestinationGatewayTest {
    function setUp() public virtual override {
        super.setUp();
        destinationGateway.initialize(bls, bn256G2, validatorSet);
    }
}

contract DestinationGatewayUninitialized is DestinationGatewayTest {
    function testInitialize() public {
        destinationGateway.initialize(bls, bn256G2, validatorSet);

        assertEq(keccak256(abi.encode(destinationGateway.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(destinationGateway.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        for (uint256 i = 0; i < validatorSet.length; i++) {
            (address _address, uint256 votingPower) = destinationGateway.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
        }
    }
}

contract DestinationGatewayReceiveBatchTests is DestinationGatewayInitialized {
    function testReceiveBatch_InvalidSignature() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        destinationGateway.receiveBatch(batch, aggMessagePoints[0], bitmaps[0]);
    }

    function testReceiveBatch_EmptyBitmap() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectRevert("BITMAP_IS_EMPTY");
        destinationGateway.receiveBatch(batch, aggMessagePoints[1], bitmaps[1]);
    }

    function testReceiveBatch_NotEnoughPower() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        destinationGateway.receiveBatch(batch, aggMessagePoints[2], bitmaps[2]);
    }

    function testReceiveBatch_Success() public {
        BridgeMessageBatch memory batch = BridgeMessageBatch({messages: msgs, sourceChainId: 2, destinationChainId: 3});

        vm.expectEmit();
        emit BridgeMessageResult(1, false, bytes(""));
        vm.expectEmit();
        emit BridgeMessageResult(2, false, bytes(""));
        destinationGateway.receiveBatch(batch, aggMessagePoints[3], bitmaps[3]);
    }
}
