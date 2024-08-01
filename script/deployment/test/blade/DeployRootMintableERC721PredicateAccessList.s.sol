// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {RootMintableERC721PredicateAccessList} from "contracts/blade/RootMintableERC721PredicateAccessList.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract RootMintableERC721PredicateAccessListDeployer is Script {
    function deployRootMintableERC721PredicateAccessList(
        address proxyAdmin,
        address newGateway,
        address newChildERC721Predicate,
        address newTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            RootMintableERC721PredicateAccessList.initialize,
            (newGateway, newChildERC721Predicate, newTokenTemplate, newUseAllowList, newUseBlockList, newOwner)
        );

        vm.startBroadcast();

        RootMintableERC721PredicateAccessList rootMintableERC721PredicateAccessList = new RootMintableERC721PredicateAccessList();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(rootMintableERC721PredicateAccessList),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(rootMintableERC721PredicateAccessList);
        proxyAddr = address(proxy);
    }
}

contract DeployRootMintableERC721PredicateAccessList is RootMintableERC721PredicateAccessListDeployer {
    function run(
        address proxyAdmin,
        address newGateway,
        address newChildERC721Predicate,
        address newTokenTemplate,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) external returns (address logicAddr, address proxyAddr) {
        return
            deployRootMintableERC721PredicateAccessList(
                proxyAdmin,
                newGateway,
                newChildERC721Predicate,
                newTokenTemplate,
                newUseAllowList,
                newUseBlockList,
                newOwner
            );
    }
}
