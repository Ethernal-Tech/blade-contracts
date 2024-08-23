// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootERC721Predicate} from "contracts/bridge/RootERC721Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootERC721PredicateDeployer is Script {
    function deployRootERC721Predicate(
        address proxyAdmin,
        address newGateway,
        address newChildERC721Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootERC721Predicate.initialize,
            (newGateway, newChildERC721Predicate, newDestinationTokenTemplate, newDestinationChainId)
        );

        vm.startBroadcast();

        RootERC721Predicate rootERC721Predicate = new RootERC721Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootERC721Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootERC721Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployRootERC721Predicate is RootERC721PredicateDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newChildERC721Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootERC721Predicate(
                proxyAdmin,
                newGateway,
                newChildERC721Predicate,
                newDestinationTokenTemplate,
                newDestinationChainId
            );
    }
}
