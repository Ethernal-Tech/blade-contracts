// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Validator {
    uint256[4] blsKey;
    uint256 stake;
    bool isWhitelisted;
    bool isActive;
}

struct GenesisValidator {
    address validator;
    uint256 stake;
    uint256[4] blsKey;
}

/**
    @title IStakeManager
    @author Polygon Technology (@gretzke)
    @notice Manages stakes for all child chains
 */
interface IStakeManager {
    event ChildManagerRegistered(uint256 indexed id, address indexed manager);
    event StakeAdded(address indexed validator, uint256 amount);
    event StakeRemoved(address indexed validator, uint256 amount);
    event StakeWithdrawn(address indexed validator, address indexed recipient, uint256 amount);
    event AddedToWhitelist(address indexed validator);
    event RemovedFromWhitelist(address indexed validator);
    event ValidatorRegistered(address indexed validator, uint256[4] blsKey);
    event ValidatorDeactivated(address indexed validator);

    error Unauthorized(string message);
    error InvalidSignature(address validator);

    /// @notice called by a validator to stake for a child chain
    function stake(uint256 amount) external;

    /// @notice called by a validator to unstake
    function unstake(uint256 amount) external;

    /// @notice allows a validator to withdraw released stake
    function withdrawStake(address to, uint256 amount) external;

    /// @notice returns the amount of stake a validator can withdraw
    function withdrawableStake(address validator) external view returns (uint256 amount);

    /// @notice returns the total amount staked for all child chains
    function totalStake() external view returns (uint256 amount);

    /// @notice returns the amount staked by a validator for a child chain
    function stakeOf(address validator) external view returns (uint256 amount);

    function whitelistValidators(address[] calldata validators_) external;

    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external;

    function getValidator(address validator_) external view returns (Validator memory);
}
