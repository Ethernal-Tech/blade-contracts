// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {EpochManager} from "contracts/child/validator/EpochManager.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

abstract contract EpochManagerDeployer is Script {
    function deployEpochManager(
        address proxyAdmin,
        address newRewardToken,
        address newRewardWallet,
        uint256 newBaseReward,
        uint256 newEpochSize
    ) internal returns (address logicAddr, address proxyAddr) {
        bytes memory initData = abi.encodeCall(
            EpochManager.initialize,
            (newRewardToken, newRewardWallet, newBaseReward, newEpochSize)
        );

        vm.startBroadcast();

        EpochManager epochManager = new EpochManager();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(epochManager),
            proxyAdmin,
            initData
        );

        vm.stopBroadcast();

        logicAddr = address(epochManager);
        proxyAddr = address(proxy);
    }
}

contract DeployRewardPool is EpochManagerDeployer {
    function run(
        address proxyAdmin,
        address newRewardToken,
        address newRewardWallet,
        uint256 newBaseReward,
        uint256 newEpochSize
    ) external returns (address logicAddr, address proxyAddr) {
        return deployEpochManager(proxyAdmin, newRewardToken, newRewardWallet, newBaseReward, newEpochSize);
    }
}
