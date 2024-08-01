// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC721Predicate} from "contracts/blade/ChildERC721Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC721PredicateDeployer is Script {
    function deployChildERC721Predicate(
        address proxyAdmin,
        address newGateway,
        address newRootERC721Predicate,
        address newDestinationTokenTemplate
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC721Predicate.initialize,
            (newGateway, newRootERC721Predicate, newDestinationTokenTemplate)
        );

        vm.startBroadcast();

        ChildERC721Predicate childERC721Predicate = new ChildERC721Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC721Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC721Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC721Predicate is ChildERC721PredicateDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newRootERC721Predicate,
        address newDestinationTokenTemplate
    ) external returns (address logicAddr, address proxyAddr) {
        return deployChildERC721Predicate(proxyAdmin, newGateway, newRootERC721Predicate, newDestinationTokenTemplate);
    }
}
