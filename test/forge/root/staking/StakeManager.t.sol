// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {StakeManager} from "contracts/child/staking/StakeManager.sol";
import {GenesisValidator} from "contracts/interfaces/root/staking/IStakeManager.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";

abstract contract Uninitialized is Test {
    MockERC20 token;
    StakeManager stakeManager;

    address blsAddr;
    address epochManagerAddr;
    string testDomain = "DUMMY_DOMAIN";

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");
    address jim = makeAddr("jim");

    function setUp() public virtual {
        token = new MockERC20();
        token.mint(alice, 1000 ether);
        token.mint(bob, 1000 ether);
        token.mint(jim, 1000 ether);

        stakeManager = new StakeManager();

        vm.prank(alice);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(bob);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(jim);
        token.approve(address(stakeManager), type(uint256).max);

        blsAddr = makeAddr("bls");
        epochManagerAddr = makeAddr("epochManager");
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        GenesisValidator[] memory validators = new GenesisValidator[](3);
        validators[0] = GenesisValidator({addr: bob, stake: 400});
        validators[1] = GenesisValidator({addr: alice, stake: 200});
        validators[2] = GenesisValidator({addr: jim, stake: 100});
        stakeManager.initialize(address(token), blsAddr, epochManagerAddr, testDomain, validators);
    }
}

abstract contract Registered is Initialized {
    uint256 maxAmount = 1000000 ether;
    address john;

    function setUp() public virtual override {
        super.setUp();
        john = makeAddr("john");
        token.mint(address(this), maxAmount * 2);
        token.mint(john, maxAmount);
        token.approve(address(stakeManager), type(uint256).max);
        vm.prank(john);
        token.approve(address(stakeManager), type(uint256).max);
    }
}

abstract contract Staked is Registered {
    function setUp() public virtual override {
        super.setUp();
        stakeManager.stake(maxAmount);
    }
}

abstract contract Unstaked is Staked {
    function setUp() public virtual override {
        super.setUp();
        vm.prank(bob);
        stakeManager.unstake(maxAmount);
    }
}

contract StakeManager_Initialize is Uninitialized {
    function testInititialize() public {
        GenesisValidator[] memory validators = new GenesisValidator[](3);
        validators[0] = GenesisValidator({addr: bob, stake: 400});
        validators[1] = GenesisValidator({addr: alice, stake: 200});
        validators[2] = GenesisValidator({addr: jim, stake: 100});
        stakeManager.initialize(address(token), blsAddr, epochManagerAddr, testDomain, validators);
    }
}

contract StakeManager_StakeFor is Registered, StakeManager {
    function test_Stake(uint256 amount) public {
        vm.assume(amount <= maxAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeAdded(address(this), amount);
        stakeManager.stake(amount);
        assertEq(stakeManager.totalStake(), amount, "total stake mismatch");
        assertEq(stakeManager.stakeOf(address(this)), amount, "stake of mismatch");
        assertEq(token.balanceOf(address(stakeManager)), amount, "token balance mismatch");
    }

    function test_StakeMultiple(uint256 amount1, uint256 amount2, uint256 amount3) public {
        vm.assume(amount1 <= maxAmount && amount2 <= maxAmount && amount3 <= maxAmount);
        stakeManager.stake(amount1);
        stakeManager.stake(amount2);
        vm.prank(john);
        stakeManager.stake(amount3);
        assertEq(stakeManager.totalStake(), amount1 + amount2 + amount3, "total stake mismatch");
        assertEq(stakeManager.stakeOf(address(this)), amount1, "stake of mismatch");
        assertEq(stakeManager.stakeOf(address(this)), amount2, "stake of mismatch");
        assertEq(stakeManager.stakeOf(john), amount3, "stake of mismatch");
        assertEq(token.balanceOf(address(stakeManager)), amount1 + amount2 + amount3, "token balance mismatch");
    }
}

contract StakeManager_ReleaseStake is Staked, StakeManager {
    function test_ReleaseStakeFor(uint256 amount) public {
        vm.assume(amount <= maxAmount);
        vm.expectEmit(true, true, true, true);
        emit StakeRemoved(address(this), amount);
        stakeManager.unstake(amount);
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
