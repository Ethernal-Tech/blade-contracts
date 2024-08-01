// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootERC20Predicate} from "contracts/bridge/RootERC20Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootERC20PredicateDeployer is Script {
    function deployRootERC20Predicate(
        address proxyAdmin,
        address newGateway,
        address newChildERC20Predicate,
        address newDestinationTokenTemplate,
        address nativeTokenRootAddress
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootERC20Predicate.initialize,
            (newGateway, newChildERC20Predicate, newDestinationTokenTemplate, nativeTokenRootAddress)
        );

        vm.startBroadcast();

        RootERC20Predicate rootERC20Predicate = new RootERC20Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootERC20Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootERC20Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootERC20Predicate is RootERC20PredicateDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newChildERC20Predicate,
        address newDestinationTokenTemplate,
        address nativeTokenRootAddress
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootERC20Predicate(
                proxyAdmin,
                newGateway,
                newChildERC20Predicate,
                newDestinationTokenTemplate,
                nativeTokenRootAddress
            );
    }
}
