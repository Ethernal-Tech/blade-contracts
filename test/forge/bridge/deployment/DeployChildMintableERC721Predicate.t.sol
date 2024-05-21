// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {DeployChildMintableERC721Predicate} from "script/deployment/bridge/DeployChildMintableERC721Predicate.s.sol";

import {ChildMintableERC721Predicate} from "contracts/bridge/ChildMintableERC721Predicate.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployChildMintableERC721PredicateTest is Test {
    DeployChildMintableERC721Predicate private deployer;

    address logicAddr;
    address proxyAddr;

    ChildMintableERC721Predicate internal proxyAsChildMintableERC721Predicate;
    ITransparentUpgradeableProxy internal proxy;

    address proxyAdmin;
    address newStateSender;
    address newExitHelper;
    address newRootERC721Predicate;
    address newChildTokenTemplate;

    function setUp() public {
        deployer = new DeployChildMintableERC721Predicate();

        proxyAdmin = makeAddr("proxyAdmin");
        newStateSender = makeAddr("newStateSender");
        newExitHelper = makeAddr("newExitHelper");
        newRootERC721Predicate = makeAddr("newRootERC721Predicate");
        newChildTokenTemplate = makeAddr("newChildTokenTemplate");

        (logicAddr, proxyAddr) = deployer.run(
            proxyAdmin,
            newStateSender,
            newExitHelper,
            newRootERC721Predicate,
            newChildTokenTemplate
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
        proxyAsChildMintableERC721Predicate.initialize(
            newStateSender,
            newExitHelper,
            newRootERC721Predicate,
            newChildTokenTemplate
        );

        assertEq(address(proxyAsChildMintableERC721Predicate.stateSender()), newStateSender);
        assertEq(proxyAsChildMintableERC721Predicate.exitHelper(), newExitHelper);
        assertEq(proxyAsChildMintableERC721Predicate.rootERC721Predicate(), newRootERC721Predicate);
        assertEq(proxyAsChildMintableERC721Predicate.childTokenTemplate(), newChildTokenTemplate);
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
        proxyAsChildMintableERC721Predicate = ChildMintableERC721Predicate(_proxyAddr);
        proxy = ITransparentUpgradeableProxy(payable(address(_proxyAddr)));
    }
}
