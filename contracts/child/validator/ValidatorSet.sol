// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../lib/WithdrawalQueue.sol";
import "../../interfaces/child/validator/IValidatorSet.sol";
import "../../interfaces/IStateSender.sol";
import "../System.sol";

contract ValidatorSet is IValidatorSet, ERC20SnapshotUpgradeable, System {
    using WithdrawalQueueLib for WithdrawalQueue;

    // TODO: @Stefan-Ethernal Move to the StakeManager?
    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;

    // TODO: @Stefan-Ethernal These fields go into RewardPool
    // slither-disable-next-line naming-convention
    uint256 public EPOCH_SIZE;

    uint256 public currentEpochId;

    mapping(uint256 => Epoch) public epochs;
    uint256[] public epochEndBlocks;
    // TODO: @Stefan-Ethernal Move to the StakeManager?
    mapping(address => WithdrawalQueue) private _withdrawals;

    // TODO: @Stefan-Ethernal move to RewardPool initialize should have only newEpochSize
    function initialize(uint256 newEpochSize, ValidatorInit[] memory initialValidators) public initializer {
        __ERC20_init("ValidatorSet", "VSET");
        EPOCH_SIZE = newEpochSize;
        for (uint256 i = 0; i < initialValidators.length; ) {
            _stake(initialValidators[i].addr, initialValidators[i].stake);
            unchecked {
                ++i;
            }
        }
        epochEndBlocks.push(0);
        currentEpochId = 1;
    }

    // TODO: @Stefan-Ethernal move commitEpoch to RewardPool (aka EpochManager)
    /**
     * @inheritdoc IValidatorSet
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

    // TODO: @Stefan-Ethernal REMOVE
    /**
     * @inheritdoc IValidatorSet
     */
    function unstake(uint256 amount) external {
        _burn(msg.sender, amount);
        _registerWithdrawal(msg.sender, amount);
    }

    // TODO: @Stefan-Ethernal Move to the StakeManager?
    /**
     * @inheritdoc IValidatorSet
     */
    function withdraw() external {
        WithdrawalQueue storage queue = _withdrawals[msg.sender];
        (uint256 amount, uint256 newHead) = queue.withdrawable(currentEpochId);
        queue.head = newHead;
        emit Withdrawal(msg.sender, amount);
    }

    // TODO: @Stefan-Ethernal Move to the StakeManager?
    /**
     * @inheritdoc IValidatorSet
     */
    // slither-disable-next-line unused-return
    function withdrawable(address account) external view returns (uint256 amount) {
        (amount, ) = _withdrawals[account].withdrawable(currentEpochId);
    }

    // TODO: @Stefan-Ethernal Move to the StakeManager?
    /**
     * @inheritdoc IValidatorSet
     */
    function pendingWithdrawals(address account) external view returns (uint256) {
        return _withdrawals[account].pending(currentEpochId);
    }

    // TODO: @Stefan-Ethernal REMOVE FOR NOW (this is going to be needed for the on-chain governance)
    /**
     * @inheritdoc IValidatorSet
     */
    function totalBlocks(uint256 epochId) external view returns (uint256 length) {
        uint256 endBlock = epochs[epochId].endBlock;
        length = endBlock == 0 ? 0 : endBlock - epochs[epochId].startBlock + 1;
    }

    // TODO: @Stefan-Ethernal REMOVE (probably will be needed in the StakeManager)
    function _registerWithdrawal(address account, uint256 amount) internal {
        _withdrawals[account].append(amount, currentEpochId + WITHDRAWAL_WAIT_PERIOD);
        emit WithdrawalRegistered(account, amount);
    }

    // TODO: @Stefan-Ethernal REMOVE
    function _stake(address validator, uint256 amount) internal {
        _mint(validator, amount);
    }

    // TODO: @Stefan-Ethernal REMOVE FOR NOW (this is going to be needed for the on-chain governance)
    /// @dev the epoch number is also the snapshot id
    function _getCurrentSnapshotId() internal view override returns (uint256) {
        return currentEpochId;
    }

    // TODO: @Stefan-Ethernal REMOVE FOR NOW (this is going to be needed for the on-chain governance)
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0) || to == address(0), "TRANSFER_FORBIDDEN");
        super._beforeTokenTransfer(from, to, amount);
    }

    // TODO: @Stefan-Ethernal REMOVE FOR NOW (this is going to be needed for the on-chain governance)
    function balanceOfAt(
        address account,
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IValidatorSet) returns (uint256) {
        return super.balanceOfAt(account, epochNumber);
    }

    // TODO: @Stefan-Ethernal REMOVE FOR NOW (this is going to be needed for the on-chain)
    function totalSupplyAt(
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IValidatorSet) returns (uint256) {
        return super.totalSupplyAt(epochNumber);
    }
}
