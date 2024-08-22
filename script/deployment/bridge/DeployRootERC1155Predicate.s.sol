// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootERC1155Predicate} from "contracts/bridge/RootERC1155Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootERC1155PredicateDeployer is Script {
    function deployRootERC1155Predicate(
        address proxyAdmin,
        address newGateway,
        address newChildERC1155Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootERC1155Predicate.initialize,
            (newGateway, newChildERC1155Predicate, newDestinationTokenTemplate, newDestinationChainId)
        );

        vm.startBroadcast();

        RootERC1155Predicate rootERC1155Predicate = new RootERC1155Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootERC1155Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootERC1155Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootERC1155Predicate is RootERC1155PredicateDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newChildERC1155Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootERC1155Predicate(
                proxyAdmin,
                newGateway,
                newChildERC1155Predicate,
                newDestinationTokenTemplate,
                newDestinationChainId
            );
    }
}
