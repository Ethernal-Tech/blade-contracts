// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployStakeManager} from "script/deployment/root/staking/DeployStakeManager.s.sol";
import {GenesisValidator} from "contracts/interfaces/root/staking/IStakeManager.sol";
import {StakeManager} from "contracts/child/staking/StakeManager.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployStakeManagerTest is Test {
    DeployStakeManager private deployer;

    address logicAddr;
    address proxyAddr;

    StakeManager internal proxyAsStakeManager;
    ITransparentUpgradeableProxy internal proxy;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    address proxyAdmin;
    address stakingTokenAddr;
    address blsAddr;
    address epochManagerAddr;
    string testDomain = "DUMMY_DOMAIN";

    function setUp() public {
        deployer = new DeployStakeManager();

        proxyAdmin = makeAddr("proxyAdmin");
        stakingTokenAddr = makeAddr("newStakingToken");
        blsAddr = makeAddr("bls");
        epochManagerAddr = makeAddr("epochManager");
        GenesisValidator[] memory initValidators = new GenesisValidator[](2);
        initValidators[0] = GenesisValidator({addr: bob, stake: 300});
        initValidators[1] = GenesisValidator({addr: alice, stake: 100});

        (logicAddr, proxyAddr) = deployer.run(
            proxyAdmin,
            stakingTokenAddr,
            blsAddr,
            epochManagerAddr,
            testDomain,
            initValidators
        );
        _recordProxy(proxyAddr);
    }

    function testRun() public {
        vm.startPrank(proxyAdmin);

        assertEq(proxy.admin(), proxyAdmin);
        assertEq(proxy.implementation(), logicAddr);

        vm.stopPrank();
    }

    function testInitialization() public {
        vm.expectRevert("Initializable: contract is already initialized");
        GenesisValidator[] memory initValidators = new GenesisValidator[](2);
        initValidators[0] = GenesisValidator({addr: bob, stake: 300});
        initValidators[1] = GenesisValidator({addr: alice, stake: 100});
        proxyAsStakeManager.initialize(stakingTokenAddr, blsAddr, epochManagerAddr, testDomain, initValidators);

        assertEq(
            vm.load(address(proxyAsStakeManager), bytes32(uint(109))),
            bytes32(bytes.concat(hex"000000000000000000000000", abi.encodePacked(stakingTokenAddr)))
        );
    }

    function testLogicChange() public {
        address newLogicAddr = makeAddr("newLogicAddr");
        vm.etch(newLogicAddr, hex"00");

        vm.startPrank(proxyAdmin);

        proxy.upgradeTo(newLogicAddr);
        assertEq(proxy.implementation(), newLogicAddr);

        vm.stopPrank();
    }

    function testAdminChange() public {
        address newAdmin = makeAddr("newAdmin");

        vm.prank(proxyAdmin);
        proxy.changeAdmin(newAdmin);

        vm.prank(newAdmin);
        assertEq(proxy.admin(), newAdmin);
    }

    function _recordProxy(address _proxyAddr) internal {
        proxyAsStakeManager = StakeManager(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
