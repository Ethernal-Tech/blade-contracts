// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import "script/deployment/bridge/DeployRootERC20Predicate.s.sol";
import "script/deployment/bridge/DeployRootERC721Predicate.s.sol";
import "script/deployment/bridge/DeployRootERC1155Predicate.s.sol";

contract DeployBridgeTokenContracts is
    RootERC20PredicateDeployer,
    RootERC721PredicateDeployer,
    RootERC1155PredicateDeployer
{
    using stdJson for string;

    function run()
        external
        returns (
            address rootERC20PredicateLogic,
            address rootERC20PredicateProxy,
            address rootERC721PredicateLogic,
            address rootERC721PredicateProxy,
            address rootERC1155PredicateLogic,
            address rootERC1155PredicateProxy
        )
    {
        string memory config = vm.readFile("script/deployment/bridgeTokenContractsConfig.json");

        (rootERC20PredicateLogic, rootERC20PredicateProxy) = deployRootERC20Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].newGateway'),
            config.readAddress('["RootERC20Predicate"].newChildERC20Predicate'),
            config.readAddress('["RootERC20Predicate"].newDestinationTokenTemplate'),
            config.readAddress('["RootERC20Predicate"].nativeTokenRootAddress'),
            config.readUint('["RootERC20Predicate"].newDestinationChainId')
        );

        (rootERC721PredicateLogic, rootERC721PredicateProxy) = deployRootERC721Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].newGateway'),
            config.readAddress('["RootERC721Predicate"].newChildERC721Predicate'),
            config.readAddress('["RootERC721Predicate"].newDestinationTokenTemplate'),
            config.readUint('["RootERC20Predicate"].newDestinationChainId')
        );

        (rootERC1155PredicateLogic, rootERC1155PredicateProxy) = deployRootERC1155Predicate(
            config.readAddress('["common"].proxyAdmin'),
            config.readAddress('["common"].newGateway'),
            config.readAddress('["RootERC1155Predicate"].newChildERC1155Predicate'),
            config.readAddress('["RootERC1155Predicate"].newDestinationTokenTemplate'),
            config.readUint('["RootERC20Predicate"].newDestinationChainId')
        );
    }
}
