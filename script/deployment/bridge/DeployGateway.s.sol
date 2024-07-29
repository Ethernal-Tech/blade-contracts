// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {Gateway} from "contracts/blade/Gateway.sol";

abstract contract GatewayDeployer is Script {
    function deployGateway() internal returns (address contractAddr) {
        vm.broadcast();
        Gateway gateway = new Gateway();

        contractAddr = address(gateway);
    }
}

contract DeployGateway is GatewayDeployer {
    function run() external returns (address contractAddr) {
        return deployGateway();
    }
}
