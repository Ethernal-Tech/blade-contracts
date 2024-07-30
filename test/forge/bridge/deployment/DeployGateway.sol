// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployGateway} from "script/deployment/bridge/DeployGateway.s.sol";

import {Gateway} from "contracts/blade/Gateway.sol";

contract DeployGatewayTest is Test {
    DeployGateway private deployer;

    Gateway internal gateway;

    function setUp() public {
        deployer = new DeployGateway();

        address contractAddr = deployer.run();
        gateway = Gateway(contractAddr);
    }

    function testRun() public {
        assertEq(gateway.counter(), 0);
    }
}
