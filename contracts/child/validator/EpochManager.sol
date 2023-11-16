// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../System.sol";
import "../../interfaces/child/validator/IEpochManager.sol";

contract EpochManager is IEpochManager, System, Initializable, ERC20SnapshotUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public rewardToken;
    address public rewardWallet;
    uint256 public baseReward;

    uint256 public EPOCH_SIZE;

    uint256 public currentEpochId;

    mapping(uint256 => Epoch) public epochs;

    uint256[] public epochEndBlocks;

    mapping(uint256 => uint256) public paidRewardPerEpoch;
    mapping(address => uint256) public pendingRewards;

    function initialize(
        address newRewardToken,
        address newRewardWallet,
        address newValidatorSet,
        uint256 newBaseReward
    ) public initializer {
        require(
            newRewardToken != address(0) && newRewardWallet != address(0) && newValidatorSet != address(0),
            "ZERO_ADDRESS"
        );

        rewardToken = IERC20Upgradeable(newRewardToken);
        rewardWallet = newRewardWallet;
        baseReward = newBaseReward;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function distributeRewardFor(uint256 epochId, Uptime[] calldata uptime) external onlySystemCall {
        require(paidRewardPerEpoch[epochId] == 0, "REWARD_ALREADY_DISTRIBUTED");
        uint256 totalBlocks = _totalBlocks(epochId);
        require(totalBlocks != 0, "EPOCH_NOT_COMMITTED");
        uint256 epochSize = EPOCH_SIZE;
        // slither-disable-next-line divide-before-multiply
        uint256 reward = (baseReward * totalBlocks) / epochSize;
        // TODO disincentivize long epoch times

        uint256 totalSupply = totalSupplyAt(epochId);
        uint256 length = uptime.length;
        uint256 totalReward = 0;
        for (uint256 i = 0; i < length; i++) {
            Uptime memory data = uptime[i];
            require(data.signedBlocks <= totalBlocks, "SIGNED_BLOCKS_EXCEEDS_TOTAL");
            // slither-disable-next-line calls-loop
            uint256 balance = balanceOfAt(data.validator, epochId);
            // slither-disable-next-line divide-before-multiply
            uint256 validatorReward = (reward * balance * data.signedBlocks) / (totalSupply * totalBlocks);
            pendingRewards[data.validator] += validatorReward;
            totalReward += validatorReward;
        }
        paidRewardPerEpoch[epochId] = totalReward;
        _transferRewards(totalReward);
        emit RewardDistributed(epochId, totalReward);
    }

    /**
     * @inheritdoc IEpochManager
     */
    function commitEpoch(uint256 id, Epoch calldata epoch) external onlySystemCall {
        uint256 newEpochId = currentEpochId++;
        require(id == newEpochId, "UNEXPECTED_EPOCH_ID");
        require(epoch.endBlock > epoch.startBlock, "NO_BLOCKS_COMMITTED");
        require((epoch.endBlock - epoch.startBlock + 1) % EPOCH_SIZE == 0, "EPOCH_MUST_BE_DIVISIBLE_BY_EPOCH_SIZE");
        require(epochs[newEpochId - 1].endBlock + 1 == epoch.startBlock, "INVALID_START_BLOCK");
        epochs[newEpochId] = epoch;
        epochEndBlocks.push(epoch.endBlock);
        emit NewEpoch(id, epoch.startBlock, epoch.endBlock, epoch.epochRoot);
    }

    /**
     * @inheritdoc IEpochManager
     */
    function withdrawReward() external {
        uint256 pendingReward = pendingRewards[msg.sender];
        pendingRewards[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, pendingReward);
    }

    /// @dev this method can be overridden to add logic depending on the reward token
    function _transferRewards(uint256 amount) internal virtual {
        // slither-disable-next-line arbitrary-send-erc20
        rewardToken.safeTransferFrom(rewardWallet, address(this), amount);
    }

    /**
     *  @inheritdoc IEpochManager
     */
    function getCurrentEpochId() external view returns (uint256) {
        return currentEpochId;
    }

    function _totalBlocks(uint256 epochId) internal view returns (uint256 length) {
        uint256 endBlock = epochs[epochId].endBlock;
        length = endBlock == 0 ? 0 : endBlock - epochs[epochId].startBlock + 1;
    }

    function totalSupplyAt(
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IEpochManager) returns (uint256) {
        return super.totalSupplyAt(epochNumber);
    }

    function balanceOfAt(
        address account,
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IEpochManager) returns (uint256) {
        return super.balanceOfAt(account, epochNumber);
    }
}
