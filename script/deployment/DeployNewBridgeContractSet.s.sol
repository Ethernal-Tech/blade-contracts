// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {GenesisAccount} from "contracts/lib/GenesisLib.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/bridge/DeployGateway.s.sol";
import "script/deployment/bridge/DeployBladeManager.s.sol";

contract DeployNewBridgeContractSet is GatewayDeployer, BladeManagerDeployer {
    using stdJson for string;

    function run()
        external
        returns (
            address proxyAdmin,
            address gatewayLogic,
            address gatewayProxy,
            address bladeManagerLogic,
            address bladeManagerProxy
        )
    {
        string memory config = vm.readFile("script/deployment/bridgeContractSetConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["ProxyAdmin"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        // TODO - change gateway and blade manager deployment
        gatewayLogic = deployGateway();

        // // To be initialized manually later.
        // GenesisAccount[] memory validators = new GenesisAccount[](0);
        // (bladeManagerLogic, bladeManagerProxy) = deployBladeManager(
        //     proxyAdmin,
        //     config.readAddress('["BladeManager"].newRootERC20Predicate'),
        //     validators
        // );
    }
}
