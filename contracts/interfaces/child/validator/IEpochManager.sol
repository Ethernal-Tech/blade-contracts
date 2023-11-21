// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Uptime {
    address validator;
    uint256 signedBlocks;
}

struct Epoch {
    uint256 startBlock;
    uint256 endBlock;
    bytes32 epochRoot;
}

/**
    @title IEpochManager
    @notice Tracks epochs and distributes rewards to validators for committed epochs
 */
interface IEpochManager {
    event RewardDistributed(uint256 indexed epochId, uint256 totalReward);
    event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot);

    /// @notice distributes reward for the given epoch
    /// @dev transfers funds from sender to this contract
    /// @param uptime uptime data for every validator
    function distributeRewardFor(uint256 epochId, Uptime[] calldata uptime) external;

    /// @notice withdraws pending rewards for the sender (validator)
    function withdrawReward() external;

    /// @notice returns the total reward paid for the given epoch
    function paidRewardPerEpoch(uint256 epochId) external view returns (uint256);

    /// @notice returns the pending reward for the given account
    function pendingRewards(address account) external view returns (uint256);

    /// @notice commits a new epoch
    /// @dev system call
    function commitEpoch(uint256 id, Epoch calldata epoch) external;

    /// @notice return currentEpochId
    function getCurrentEpochId() external view returns (uint256);

    /// @notice returns the total supply for a given epoch
    function totalSupplyAt(uint256 epochNumber) external view returns (uint256);

    /// @notice returns a validator balance for a given epoch
    function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256);
}
