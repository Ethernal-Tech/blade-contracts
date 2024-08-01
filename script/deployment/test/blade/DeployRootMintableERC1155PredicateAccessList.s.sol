// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootMintableERC1155PredicateAccessList} from "contracts/blade/RootMintableERC1155PredicateAccessList.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootMintableERC1155PredicateAccessListDeployer is Script {
    function deployRootMintableERC1155PredicateAccessList(
        address proxyAdmin,
        address newGateway,
        address newChildERC1155Predicate,
        address newTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootMintableERC1155PredicateAccessList.initialize,
            (newGateway, newChildERC1155Predicate, newTokenTemplate, newUseAllowList, newUseBlockList, newOwner)
        );

        vm.startBroadcast();

        RootMintableERC1155PredicateAccessList rootMintableERC1155PredicateAccessList = new RootMintableERC1155PredicateAccessList();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootMintableERC1155PredicateAccessList),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootMintableERC1155PredicateAccessList);
        proxyAddr = address(proxy);
    }
}

contract DeployRootMintableERC1155PredicateAccessList is RootMintableERC1155PredicateAccessListDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newChildERC1155Predicate,
        address newTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootMintableERC1155PredicateAccessList(
                proxyAdmin,
                newGateway,
                newChildERC1155Predicate,
                newTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            );
    }
}
