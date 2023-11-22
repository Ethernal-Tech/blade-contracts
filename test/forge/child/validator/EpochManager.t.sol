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
        epochManager = new EpochManager();
        token.mint(rewardWallet, 1000 ether);
        vm.prank(rewardWallet);
        token.approve(address(epochManager), type(uint256).max);
    }
}

abstract contract Initialized is Uninitialized {
    function setUp() public virtual override {
        super.setUp();
        epochManager.initialize(address(token), rewardWallet, 1 ether, 10);

        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        vm.roll(block.number + 1);
        epochManager.commitEpoch(1, epoch);
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

contract EpochManager_Initialize is Uninitialized {
    function test_Initialize() public {
        epochManager.initialize(address(token), rewardWallet, 1 ether, epochSize);
        assertEq(address(epochManager.rewardToken()), address(token));
        assertEq(epochManager.rewardWallet(), rewardWallet);
        assertEq(epochManager.epochSize(), epochSize);
    }
}

contract EpochManager_TransferForbidden is Initialized {
    function test_RevertTransfer() public {
        vm.expectRevert("TRANSFER_FORBIDDEN");
        epochManager.transfer(alice, 100);
    }
}

contract EpochManager_CommitEpoch is Initialized {
    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);

    function test_RevertOnlySystemCall() public {
        vm.prank(alice);
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector, "SYSTEMCALL"));
        epochManager.commitEpoch(1, epoch);
    }

    function test_RevertInvalidEpochId(uint256 id) public {
        vm.assume(id != 1);
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.expectRevert("UNEXPECTED_EPOCH_ID");
        vm.prank(SYSTEM);
        epochManager.commitEpoch(id, epoch);
    }

    function test_RevertNoBlocksCommitted(uint256 startBlock, uint256 endBlock) public {
        vm.assume(endBlock <= startBlock);
        Epoch memory epoch = Epoch({startBlock: startBlock, endBlock: endBlock, epochRoot: bytes32(0)});
        vm.expectRevert("NO_BLOCKS_COMMITTED");
        vm.prank(SYSTEM);
        epochManager.commitEpoch(1, epoch);
    }

    function test_RevertEpochSize(uint256 startBlock, uint256 endBlock) public {
        vm.assume(endBlock > startBlock && endBlock < type(uint256).max);
        vm.assume((endBlock - startBlock + 1) % epochSize != 0);
        Epoch memory epoch = Epoch({startBlock: startBlock, endBlock: endBlock, epochRoot: bytes32(0)});
        vm.expectRevert("EPOCH_MUST_BE_DIVISIBLE_BY_EPOCH_SIZE");
        vm.prank(SYSTEM);
        epochManager.commitEpoch(1, epoch);
    }

    function test_RevertInvalidStartBlock() public {
        Epoch memory epoch = Epoch({startBlock: 0, endBlock: 63, epochRoot: bytes32(0)});
        vm.expectRevert("INVALID_START_BLOCK");
        vm.prank(SYSTEM);
        epochManager.commitEpoch(1, epoch);
    }

    function test_CommitEpoch() public {
        Epoch memory epoch = Epoch({startBlock: 1, endBlock: 64, epochRoot: bytes32(0)});
        vm.prank(SYSTEM);
        vm.expectEmit(true, true, true, true);
        emit NewEpoch(1, 1, 64, bytes32(0));
        epochManager.commitEpoch(1, epoch);
        assertEq(epochManager.currentEpochId(), 2);
        assertEq(epochManager.epochEndBlocks(1), 64);
    }
}

contract EpochManager_Distribute is Initialized {
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

contract EpochManager_DuplicateDistribution is Distributed {
    function test_RevertEpochAlreadyDistributed() public {
        Uptime[] memory uptime = new Uptime[](0);
        vm.startPrank(SYSTEM);
        vm.expectRevert("REWARD_ALREADY_DISTRIBUTED");
        epochManager.distributeRewardFor(1, uptime);
    }
}

contract EpochManager_Withdrawal is Distributed {
    function test_SuccessfulWithdrawal() public {
        uint256 reward = epochManager.pendingRewards(address(this));
        epochManager.withdrawReward();
        assertEq(epochManager.pendingRewards(address(this)), 0);
        assertEq(token.balanceOf(address(this)), reward);
    }
}


