// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ChildERC20Predicate} from "contracts/blade/ChildERC20Predicate.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract ChildERC20PredicateDeployer is Script {
    function deployChildERC20Predicate(
        address proxyAdmin,
        address newGateway,
        address newRootERC20Predicate,
        address newDestinationTokenTemplate,
        address newNativeTokenRootAddress,
        uint256 newDestinationChainId
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            ChildERC20Predicate.initialize,
            (
                newGateway,
                newRootERC20Predicate,
                newDestinationTokenTemplate,
                newNativeTokenRootAddress,
                newDestinationChainId
            )
        );

        vm.startBroadcast();

        ChildERC20Predicate childERC20Predicate = new ChildERC20Predicate();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(childERC20Predicate),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(childERC20Predicate);
        proxyAddr = address(proxy);
    }
}

contract DeployChildERC20Predicate is ChildERC20PredicateDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployChildERC20Predicate(
                proxyAdmin,
                newGateway,
                newRootERC20Predicate,
                newChildTokenTemplate,
                newDestinationTokenTemplate,
                newDestinationChainId
            );
    }
}
