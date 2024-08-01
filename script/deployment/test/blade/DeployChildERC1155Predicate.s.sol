// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC1155Predicate} from "contracts/blade/ChildERC1155Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC1155PredicateDeployer is Script {
    function deployChildERC1155Predicate(
        address proxyAdmin,
        address newGateway,
        address newRootERC1155Predicate,
        address newDestinationTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC1155Predicate.initialize,
            (newGateway, newRootERC1155Predicate, newDestinationTokenTemplate)
        );

        vm.startBroadcast();

        ChildERC1155Predicate childERC1155Predicate = new ChildERC1155Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC1155Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC1155Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC1155Predicate is ChildERC1155PredicateDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newRootERC1155Predicate,
        address newDestinationTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildERC1155Predicate(proxyAdmin, newGateway, newRootERC1155Predicate, newDestinationTokenTemplate);
    }
}
