// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@utils/Test.sol";
import {MockERC20} from "contracts/mocks/MockERC20.sol";
import {EpochManager} from "contracts/child/validator/EpochManager.sol";
import {Epoch, Uptime} from "contracts/interfaces/child/validator/IEpochManager.sol";
import "contracts/interfaces/Errors.sol";

abstract contract Uninitialized is Test {
    address public constant SYSTEM = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

    MockERC20 token;
    EpochManager epochManager;
    address rewardWallet = makeAddr("rewardWallet");
    address alice = makeAddr("alice");
    uint256 epochSize = 64;

    function setUp() public virtual {
        token = new MockERC20();
        ValidatorInit[] memory init = new ValidatorInit[](2);
        init[0] = ValidatorInit({addr: address(this), stake: 300});
        init[1] = ValidatorInit({addr: alice, stake: 100});
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        vm.roll(block.number + 1);
        epochManager = new EpochManager();
        epochManager.commitEpoch(1, epoch);
        token.mint(rewardWallet, 1000 ether);
        vm.prank(rewardWallet);
        token.approve(address(epochManager), type(uint256).max);
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        epochManager.initialize(address(token), rewardWallet, 1 ether, 10);
    }
}

abstract contract Distributed is Initialized {
    function setUp() public virtual override {
        super.setUp();
        Uptime[] memory uptime = new Uptime[](2);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 64});
        uptime[1] = Uptime({validator: alice, signedBlocks: 64});
        vm.prank(SYSTEM);
        epochManager.distributeRewardFor(1, uptime);
    }
}

contract RewardPool_Initialize is Uninitialized {
    function test_Initialize() public {
        epochManager.initialize(address(token), rewardWallet, address(validatorSet), 1 ether, epochSize);
        assertEq(address(epochManager.rewardToken()), address(token));
        assertEq(epochManager.rewardWallet(), rewardWallet);
        assertEq(address(epochManager.epochSize()), epochSize);
    }
}

contract RewardPool_Distribute is Initialized {
    event RewardDistributed(uint256 indexed epochId, uint256 totalReward);

    function test_RevertOnlySystem() public {
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        epochManager.distributeRewardFor(1, new Uptime[](0));
    }

    function test_RevertGenesisEpoch() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.expectRevert("EPOCH_NOT_COMMITTED");
        vm.prank(SYSTEM);
        epochManager.distributeRewardFor(0, uptime);
    }

    function test_RevertFutureEpoch() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.expectRevert("EPOCH_NOT_COMMITTED");
        vm.prank(SYSTEM);
        epochManager.distributeRewardFor(2, uptime);
    }

    function test_RevertSignedBlocksExceedsTotalBlocks() public {
        Uptime[] memory uptime = new Uptime[](1);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 65});
        vm.prank(SYSTEM);
        vm.expectRevert("SIGNED_BLOCKS_EXCEEDS_TOTAL");
        epochManager.distributeRewardFor(1, uptime);
    }

    function test_DistributeRewards() public {
        Uptime[] memory uptime = new Uptime[](2);
        uptime[0] = Uptime({validator: address(this), signedBlocks: 60});
        uptime[1] = Uptime({validator: alice, signedBlocks: 50});
        uint256 reward1 = (1 ether * 3 * 60) / (4 * 64);
        uint256 reward2 = (1 ether * 1 * 50) / (4 * 64);
        uint256 totalReward = reward1 + reward2;
        vm.prank(SYSTEM);
        vm.expectEmit(true, true, true, true);
        emit RewardDistributed(1, totalReward);
        epochManager.distributeRewardFor(1, uptime);
        assertEq(epochManager.pendingRewards(address(this)), reward1);
        assertEq(epochManager.pendingRewards(alice), reward2);
        assertEq(epochManager.paidRewardPerEpoch(1), totalReward);
    }
}

contract RewardPool_DuplicateDistribution is Distributed {
    function test_RevertEpochAlreadyDistributed() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.startPrank(SYSTEM);
        vm.expectRevert("REWARD_ALREADY_DISTRIBUTED");
        epochManager.distributeRewardFor(1, uptime);
    }
}

contract RewardPool_Withdrawal is Distributed {
    function test_SuccessfulWithdrawal() public {
        uint256 reward = epochManager.pendingRewards(address(this));
        epochManager.withdrawReward();
        assertEq(epochManager.pendingRewards(address(this)), 0);
        assertEq(token.balanceOf(address(this)), reward);
    }
}
