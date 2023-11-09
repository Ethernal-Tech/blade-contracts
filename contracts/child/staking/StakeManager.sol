// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/root/staking/IStakeManager.sol";
import "../../interfaces/IStateSender.sol";
import "./StakeManagerStakingData.sol";
import "../../interfaces/common/IBLS.sol";

contract StakeManager is IStakeManager, Initializable, StakeManagerStakingData {
    using SafeERC20 for IERC20;
    using GenesisLib for GenesisSet;

    bytes32 private constant _STAKE_SIG = keccak256("STAKE");
    bytes32 private constant _UNSTAKE_SIG = keccak256("UNSTAKE");

    IBLS private _bls;
    IERC20 private _stakingToken;

    bytes32 public domain;

    mapping(address => Validator) public validators;

    modifier onlyValidator(address validator) {
        if (!validators[validator].isActive) revert Unauthorized("VALIDATOR");
        _;
    }

    function initialize(
        address newStakingToken,
        address newBls,
        string memory newDomain,
        StartValidator[] memory genesisValidators
    ) public initializer {
        _stakingToken = IERC20(newStakingToken);
        _bls = IBLS(newBls);
        domain = keccak256(abi.encodePacked(newDomain));
        for (uint i = 0; i < genesisValidators.length; i++) {
            validators[genesisValidators[i].validator] = Validator(
                genesisValidators[i].blsKey,
                genesisValidators[i].stake,
                true,
                true
            );
        }
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stake(uint256 amount) external {
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        // calling the library directly once fixes the coverage issue
        // https://github.com/foundry-rs/foundry/issues/4854#issuecomment-1528897219
        _addStake(msg.sender, amount);
        // slither-disable-next-line reentrancy-events
        emit StakeAdded(msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawStake(address to, uint256 amount) external {
        _withdrawStake(msg.sender, to, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawableStake(address validator) external view returns (uint256 amount) {
        amount = _withdrawableStakeOf(validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStake() external view returns (uint256 amount) {
        amount = _totalStake;
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeOf(address validator) external view returns (uint256 amount) {
        amount = _stakeOf(validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function whitelistValidators(address[] calldata validators_) external {
        uint256 length = validators_.length;
        for (uint256 i = 0; i < length; i++) {
            _addToWhitelist(validators_[i]);
        }
    }

    /**
     * @inheritdoc IStakeManager
     */
    function register(uint256[2] calldata signature, uint256[4] calldata pubkey) external {
        Validator storage validator = validators[msg.sender];
        if (!validator.isWhitelisted) revert Unauthorized("WHITELIST");
        _verifyValidatorRegistration(msg.sender, signature, pubkey);
        validator.blsKey = pubkey;
        validator.isActive = true;
        _removeFromWhitelist(msg.sender);
        emit ValidatorRegistered(msg.sender, pubkey);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function getValidator(address validator_) external view returns (Validator memory) {
        return validators[validator_];
    }

    function _withdrawStake(address validator, address to, uint256 amount) private {
        _withdrawStake(validator, amount);
        // slither-disable-next-line reentrancy-events
        _stakingToken.safeTransfer(to, amount);
        emit StakeWithdrawn(validator, to, amount);
    }

    function _addToWhitelist(address validator) internal {
        validators[validator].isWhitelisted = true;
        emit AddedToWhitelist(validator);
    }

    function _removeFromWhitelist(address validator) internal {
        validators[validator].isWhitelisted = false;
        emit RemovedFromWhitelist(validator);
    }

    function _verifyValidatorRegistration(
        address signer,
        uint256[2] calldata signature,
        uint256[4] calldata pubkey
    ) internal view {
        /// @dev signature verification succeeds if signature and pubkey are empty
        if (signature[0] == 0 && signature[1] == 0) revert InvalidSignature(signer);
        // slither-disable-next-line calls-loop
        (bool result, bool callSuccess) = _bls.verifySingle(signature, pubkey, _message(signer));
        if (!callSuccess || !result) revert InvalidSignature(signer);
    }

    function _unstake(address validator, uint256 amount) internal {
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        releaseStakeOf(validator, amount);
        _removeIfValidatorUnstaked(validator);
    }

    function releaseStakeOf(address validator, uint256 amount) internal {
        _removeStake(validator, amount);
        // slither-disable-next-line reentrancy-events
        emit StakeRemoved(validator, amount);
    }

    /// @notice Message to sign for registration
    function _message(address signer) internal view returns (uint256[2] memory) {
        // slither-disable-next-line calls-loop
        return _bls.hashToPoint(domain, abi.encodePacked(signer, address(this), block.chainid));
    }

    function _removeIfValidatorUnstaked(address validator) internal {
        if (_stakeOf(validator) == 0) {
            validators[validator].isActive = false;
            emit ValidatorDeactivated(validator);
        }
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[48] private __gap;
}