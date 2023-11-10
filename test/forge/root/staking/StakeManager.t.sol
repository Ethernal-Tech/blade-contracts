// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {StakeManager} from "contracts/child/staking/StakeManager.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";

abstract contract Uninitialized is Test {
    MockERC20 token;
    StakeManager stakeManager;

    function setUp() public virtual {
        token = new MockERC20();
        stakeManager = new StakeManager();
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        stakeManager.initialize(address(token));
    }
}

abstract contract Registered is Initialized {
    uint256 maxAmount = 1000000 ether;
    address alice;

    function setUp() public virtual override {
        super.setUp();
        alice = makeAddr("alice");
        token.mint(address(this), maxAmount * 2);
        token.mint(alice, maxAmount);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(alice);
        token.approve(address(stakeManager), type(uint256).max);
    }
}

abstract contract Staked is Registered {
    function setUp() public virtual override {
        super.setUp();
        stakeManager.stakeFor(id, maxAmount);
    }
}

abstract contract Unstaked is Staked {
    address bob = makeAddr("bob");

    function setUp() public virtual override {
        super.setUp();
        vm.prank(address(supernetManager));
        stakeManager.releaseStakeOf(address(this), maxAmount);
    }
}

contract StakeManager_Initialize is Uninitialized {
    function testInititialize() public {
        stakeManager.initialize(address(token));
    }
}

contract StakeManager_StakeFor is Registered, StakeManager {
    function test_RevertIdZero() public {
        vm.expectRevert("StakeManager: INVALID_ID");
        stakeManager.stakeFor(0, 1);
    }

    function test_RevertChainDoesNotExist() public {
        vm.expectRevert("StakeManager: INVALID_ID");
        stakeManager.stakeFor(id2 + 1, 1);
    }

    function test_StakeFor(uint256 amount) public {
        vm.assume(amount <= maxAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeAdded(id, address(this), amount);
        stakeManager.stake(amount);
        assertEq(stakeManager.totalStake(), amount, "total stake mismatch");
        assertEq(stakeManager.stakeOf(address(this)), amount, "stake of mismatch");
        assertEq(token.balanceOf(address(stakeManager)), amount, "token balance mismatch");
    }

    function test_StakeForMultiple(uint256 amount1, uint256 amount2, uint256 amount3) public {
        vm.assume(amount1 <= maxAmount && amount2 <= maxAmount && amount3 <= maxAmount);
        stakeManager.stake(amount1);
        stakeManager.stake(amount2);
        vm.prank(alice);
        stakeManager.stake(amount3);
        assertEq(stakeManager.totalStake(), amount1 + amount2 + amount3, "total stake mismatch");
        assertEq(stakeManager.stakeOf(address(this)), amount1, "stake of mismatch");
        assertEq(stakeManager.stakeOf(address(this)), amount2, "stake of mismatch");
        assertEq(stakeManager.stakeOf(alice), amount3, "stake of mismatch");
        assertEq(token.balanceOf(address(stakeManager)), amount1 + amount2 + amount3, "token balance mismatch");
    }
}

contract StakeManager_ReleaseStake is Staked, StakeManager {
    function test_RevertNotSupernetManager() public {
        vm.expectRevert("StakeManagerChildData: INVALID_MANAGER");
        stakeManager.releaseStakeOf(address(this), 1);
    }

    function test_ReleaseStakeFor(uint256 amount) public {
        vm.assume(amount <= maxAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeRemoved(id, address(this), amount);
        stakeManager.releaseStakeOf(address(this), amount);
        assertEq(stakeManager.totalStake(), maxAmount - amount, "total stake mismatch");
        assertEq(stakeManager.stakeOf(address(this)), maxAmount - amount, "stake of mismatch");
        assertEq(stakeManager.withdrawableStake(address(this)), amount, "withdrawable stake mismatch");
    }
}

contract StakeManager_WithdrawStake is Unstaked, StakeManager {
    function test_WithdrawStake(uint256 amount) public {
        vm.assume(amount <= maxAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeWithdrawn(address(this), bob, amount);
        stakeManager.withdrawStake(bob, amount);
        assertEq(stakeManager.withdrawableStake(address(this)), maxAmount - amount, "withdrawable stake mismatch");
    }
}
