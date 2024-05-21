// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployRootERC20Predicate} from "script/deployment/bridge/DeployRootERC20Predicate.s.sol";

import {RootERC20Predicate} from "contracts/bridge/RootERC20Predicate.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployRootERC20PredicateTest is Test {
    DeployRootERC20Predicate private deployer;

    address logicAddr;
    address proxyAddr;

    RootERC20Predicate internal proxyAsRootERC20Predicate;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    address newStateSender;
    address newExitHelper;
    address newChildERC20Predicate;
    address newChildTokenTemplate;
    address nativeTokenRootAddress;

    function setUp() public {
        deployer = new DeployRootERC20Predicate();

        proxyAdmin = makeAddr("proxyAdmin");
        newStateSender = makeAddr("newStateSender");
        newExitHelper = makeAddr("newExitHelper");
        newChildERC20Predicate = makeAddr("newChildERC20Predicate");
        newChildTokenTemplate = makeAddr("newChildTokenTemplate");
        nativeTokenRootAddress = makeAddr("nativeTokenRootAddress");

        (logicAddr, proxyAddr) = deployer.run(
            proxyAdmin,
            newStateSender,
            newExitHelper,
            newChildERC20Predicate,
            newChildTokenTemplate,
            nativeTokenRootAddress
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
        proxyAsRootERC20Predicate.initialize(
            newStateSender,
            newExitHelper,
            newChildERC20Predicate,
            newChildTokenTemplate,
            nativeTokenRootAddress,
            proxyAdmin
        );

        assertEq(address(proxyAsRootERC20Predicate.stateSender()), newStateSender);
        assertEq(proxyAsRootERC20Predicate.exitHelper(), newExitHelper);
        assertEq(proxyAsRootERC20Predicate.childERC20Predicate(), newChildERC20Predicate);
        assertEq(proxyAsRootERC20Predicate.childTokenTemplate(), newChildTokenTemplate);
        assertEq(
            proxyAsRootERC20Predicate.rootTokenToChildToken(nativeTokenRootAddress),
            address(0x0000000000000000000000000000000000001010)
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
        proxyAsRootERC20Predicate = RootERC20Predicate(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
