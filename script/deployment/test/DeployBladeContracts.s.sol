// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "script/deployment/test/blade/DeployChildERC20.s.sol";
import "script/deployment/test/blade/DeployChildERC20Predicate.s.sol";
import "script/deployment/test/blade/DeployChildERC20PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployChildERC721.s.sol";
import "script/deployment/test/blade/DeployChildERC721Predicate.s.sol";
import "script/deployment/test/blade/DeployChildERC721PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployChildERC1155.s.sol";
import "script/deployment/test/blade/DeployChildERC1155Predicate.s.sol";
import "script/deployment/test/blade/DeployChildERC1155PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployEIP1559Burn.s.sol";
import "script/deployment/test/blade/DeployGateway.s.sol";
import "script/deployment/test/blade/validator/DeployEpochManager.s.sol";
import "script/deployment/test/blade/DeployNativeERC20.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC20PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC721PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeployRootMintableERC1155PredicateAccessList.s.sol";
import "script/deployment/test/blade/DeploySystem.s.sol";
import "script/deployment/test/blade/staking/DeployStakeManager.s.sol";

contract DeployBladeContracts is
    EpochManagerDeployer,
    ChildERC20Deployer,
    ChildERC20PredicateDeployer,
    ChildERC20PredicateAccessListDeployer,
    ChildERC721Deployer,
    ChildERC721PredicateDeployer,
    ChildERC721PredicateAccessListDeployer,
    ChildERC1155Deployer,
    ChildERC1155PredicateDeployer,
    ChildERC1155PredicateAccessListDeployer,
    EIP1559BurnDeployer,
    GatewayDeployer,
    NativeERC20Deployer,
    RootMintableERC20PredicateAccessListDeployer,
    RootMintableERC721PredicateAccessListDeployer,
    RootMintableERC1155PredicateAccessListDeployer,
    SystemDeployer,
    StakeManagerDeployer
{
    using stdJson for string;

    address public proxyAdmin;
    address public epochManagerLogic;
    address public epochManagerProxy;
    address public childERC20Logic;
    address public childERC20Proxy;
    address public childERC20PredicateLogic;
    address public childERC20PredicateProxy;
    address public childERC20PredicateAccessListLogic;
    address public childERC20PredicateAccessListProxy;
    address public childERC721Logic;
    address public childERC721Proxy;
    address public childERC721PredicateLogic;
    address public childERC721PredicateProxy;
    address public childERC721PredicateAccessListLogic;
    address public childERC721PredicateAccessListProxy;
    address public childERC1155Logic;
    address public childERC1155Proxy;
    address public childERC1155PredicateLogic;
    address public childERC1155PredicateProxy;
    address public childERC1155PredicateAccessListLogic;
    address public childERC1155PredicateAccessListProxy;
    address public eip1559BurnLogic;
    address public eip1559BurnProxy;
    address public gateway;
    address public nativeERC20Logic;
    address public nativeERC20Proxy;
    address public rootMintableERC20PredicateAccessListLogic;
    address public rootMintableERC20PredicateAccessListProxy;
    address public rootMintableERC721PredicateAccessListLogic;
    address public rootMintableERC721PredicateAccessListProxy;
    address public rootMintableERC1155PredicateAccessListLogic;
    address public rootMintableERC1155PredicateAccessListProxy;
    address public system;
    address public stakeManagerLogic;
    address public stakeManagerProxy;

    function run() external {
        string memory config = vm.readFile("script/deployment/bladeContractsConfig.json");

        vm.startBroadcast();

        ProxyAdmin _proxyAdmin = new ProxyAdmin();
        _proxyAdmin.transferOwnership(config.readAddress('["ProxyAdmin"].proxyAdminOwner'));

        vm.stopBroadcast();

        proxyAdmin = address(_proxyAdmin);

        (epochManagerLogic, epochManagerProxy) = deployEpochManager(
            proxyAdmin,
            config.readAddress('["EpochManager"].newStakeManager'),
            config.readAddress('["EpochManager"].newRewardToken'),
            config.readAddress('["EpochManager"].newRewardWallet'),
            config.readAddress('["EpochManager"].newNetworkParams')
        );

        (childERC20Logic, childERC20Proxy) = deployChildERC20(
            proxyAdmin,
            config.readAddress('["ChildERC20"].rootToken_'),
            config.readString('["ChildERC20"].name_'),
            config.readString('["ChildERC20"].symbol_'),
            uint8(config.readUint('["ChildERC20"].decimals_'))
        );

        gateway = deployGateway();

        (childERC20PredicateLogic, childERC20PredicateProxy) = deployChildERC20Predicate(
            proxyAdmin,
            gateway,
            config.readAddress('["ChildERC20Predicate"].newRootERC20Predicate'),
            config.readAddress('["ChildERC20Predicate"].newDestinationTokenTemplate'),
            config.readAddress('["ChildERC20Predicate"].newNativeTokenRootAddress'),
            config.readUint('["ChildERC20Predicate"].newDestinationChainId')
        );

        (childERC20PredicateAccessListLogic, childERC20PredicateAccessListProxy) = deployChildERC20PredicateAccessList(
            proxyAdmin,
            gateway,
            config.readAddress('["ChildERC20PredicateAccessList"].newRootERC20Predicate'),
            config.readAddress('["ChildERC20PredicateAccessList"].newDestinationTokenTemplate'),
            config.readAddress('["ChildERC20PredicateAccessList"].newNativeTokenRootAddress'),
            config.readUint('["ChildERC20PredicateAccessList"].newDestinationChainId'),
            config.readBool('["ChildERC20PredicateAccessList"].newUseAllowList'),
            config.readBool('["ChildERC20PredicateAccessList"].newUseBlockList'),
            config.readAddress('["ChildERC20PredicateAccessList"].newOwner')
        );

        (childERC721Logic, childERC721Proxy) = deployChildERC721(
            proxyAdmin,
            config.readAddress('["ChildERC721"].rootToken_'),
            config.readString('["ChildERC721"].name_'),
            config.readString('["ChildERC721"].symbol_')
        );

        (childERC721PredicateLogic, childERC721PredicateProxy) = deployChildERC721Predicate(
            proxyAdmin,
            gateway,
            config.readAddress('["ChildERC721Predicate"].newRootERC721Predicate'),
            config.readAddress('["ChildERC721Predicate"].newDestinationTokenTemplate'),
            config.readUint('["ChildERC721Predicate"].newDestinationChainId')
        );

        (
            childERC721PredicateAccessListLogic,
            childERC721PredicateAccessListProxy
        ) = deployChildERC721PredicateAccessList(
            proxyAdmin,
            gateway,
            config.readAddress('["ChildERC721PredicateAccessList"].newRootERC721Predicate'),
            config.readAddress('["ChildERC721PredicateAccessList"].newDestinationTokenTemplate'),
            config.readUint('["ChildERC721PredicateAccessList"].newDestinationChainId'),
            config.readBool('["ChildERC721PredicateAccessList"].newUseAllowList'),
            config.readBool('["ChildERC721PredicateAccessList"].newUseBlockList'),
            config.readAddress('["ChildERC721PredicateAccessList"].newOwner')
        );

        (childERC1155Logic, childERC1155Proxy) = deployChildERC1155(
            proxyAdmin,
            config.readAddress('["ChildERC1155"].rootToken_'),
            config.readString('["ChildERC1155"].uri_')
        );

        (childERC1155PredicateLogic, childERC1155PredicateProxy) = deployChildERC1155Predicate(
            proxyAdmin,
            gateway,
            config.readAddress('["ChildERC1155Predicate"].newRootERC1155Predicate'),
            config.readAddress('["ChildERC1155Predicate"].newDestinationTokenTemplate'),
            config.readUint('["ChildERC1155Predicate"].newDestinationChainId')
        );

        (
            childERC1155PredicateAccessListLogic,
            childERC1155PredicateAccessListProxy
        ) = deployChildERC1155PredicateAccessList(
            proxyAdmin,
            gateway,
            config.readAddress('["ChildERC1155PredicateAccessList"].newRootERC1155Predicate'),
            config.readAddress('["ChildERC1155PredicateAccessList"].newDestinationTokenTemplate'),
            config.readUint('["ChildERC1155PredicateAccessList"].newDestinationChainId'),
            config.readBool('["ChildERC1155PredicateAccessList"].newUseAllowList'),
            config.readBool('["ChildERC1155PredicateAccessList"].newUseBlockList'),
            config.readAddress('["ChildERC1155PredicateAccessList"].newOwner')
        );

        (eip1559BurnLogic, eip1559BurnProxy) = deployEIP1559Burn(
            proxyAdmin,
            IChildERC20Predicate(childERC20PredicateProxy),
            config.readAddress('["EIP1559Burn"].newBurnDestination')
        );

        (nativeERC20Logic, nativeERC20Proxy) = deployNativeERC20(
            proxyAdmin,
            config.readAddress('["NativeERC20"].predicate_'),
            config.readAddress('["NativeERC20"].rootToken_'),
            config.readString('["NativeERC20"].name_'),
            config.readString('["NativeERC20"].symbol_'),
            uint8(config.readUint('["NativeERC20"].decimals_')),
            config.readUint('["NativeERC20"].tokenSupply_')
        );

        (
            rootMintableERC721PredicateAccessListLogic,
            rootMintableERC721PredicateAccessListProxy
        ) = deployRootMintableERC721PredicateAccessList(
            proxyAdmin,
            gateway,
            childERC721PredicateProxy,
            config.readAddress('["RootMintableERC721PredicateAccessList"].newTokenTemplate'),
            config.readUint('["RootMintableERC721PredicateAccessList"].newDestinationChainId'),
            config.readBool('["RootMintableERC721PredicateAccessList"].newUseAllowList'),
            config.readBool('["RootMintableERC721PredicateAccessList"].newUseBlockList'),
            config.readAddress('["RootMintableERC721PredicateAccessList"].newOwner')
        );

        (
            rootMintableERC1155PredicateAccessListLogic,
            rootMintableERC1155PredicateAccessListProxy
        ) = deployRootMintableERC1155PredicateAccessList(
            proxyAdmin,
            gateway,
            childERC1155PredicateProxy,
            config.readAddress('["RootMintableERC1155PredicateAccessList"].newTokenTemplate'),
            config.readUint('["RootMintableERC1155PredicateAccessList"].newDestinationChainId'),
            config.readBool('["RootMintableERC1155PredicateAccessList"].newUseAllowList'),
            config.readBool('["RootMintableERC1155PredicateAccessList"].newUseBlockList'),
            config.readAddress('["RootMintableERC1155PredicateAccessList"].newOwner')
        );

        (stakeManagerLogic, stakeManagerProxy) = deployStakeManager(
            proxyAdmin,
            config.readAddress('["StakeManager"].newStakingToken'),
            config.readAddress('["StakeManager"].newBls'),
            config.readAddress('["StakeManager"].newEpochManager'),
            config.readAddress('["EpochManager"].newNetworkParams'),
            config.readAddress('["StakeManager"].newOwner'),
            config.readString('["StakeManager"].newDomain'),
            abi.decode(config.readBytes('["StakeManager"].newGenesisValidators'), (GenesisValidator[]))
        );

        system = deploySystem();
    }
}
