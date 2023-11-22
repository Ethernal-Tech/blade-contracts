// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20SnapshotUpgradeable.sol";
import "../../interfaces/root/staking/IStakeManager.sol";
import "../../interfaces/IStateSender.sol";
import "../../interfaces/common/IBLS.sol";
import "../../interfaces/child/validator/IEpochManager.sol";
import "../../lib/WithdrawalQueue.sol";

contract StakeManager is IStakeManager, Initializable, Ownable2StepUpgradeable, ERC20SnapshotUpgradeable {
    using SafeERC20 for IERC20;
    using WithdrawalQueueLib for WithdrawalQueue;

    uint256 public constant WITHDRAWAL_WAIT_PERIOD = 1;

    // slither-disable-next-line naming-convention
    uint256 internal _totalStake;
    // validator address => withdrawable stake.
    mapping(address => uint256) private _withdrawableStakes;

    IBLS private _bls;
    IERC20 private _stakingToken;
    IEpochManager private _epochManager;

    bytes32 public domain;

    mapping(address => Validator) public validators;

    // TODO: Figure out the unstake and stake withdrawal workflow (unlock period etc.)
    mapping(address => WithdrawalQueue) private _withdrawals;

    modifier onlyValidator(address validator) {
        if (!validators[validator].isActive) revert Unauthorized("VALIDATOR");
        _;
    }

    function initialize(
        address newStakingToken,
        address newBls,
        address epochManager,
        string memory newDomain,
        GenesisValidator[] memory genesisValidators
    ) public initializer {
        __ERC20_init("StakeManager", "STAKE");
        _stakingToken = IERC20(newStakingToken);
        _bls = IBLS(newBls);
        _epochManager = IEpochManager(epochManager);
        domain = keccak256(abi.encodePacked(newDomain));

        uint256 localTotalStake = 0;
        for (uint i = 0; i < genesisValidators.length; i++) {
            GenesisValidator memory validator = genesisValidators[i];
            validators[validator.addr] = Validator(validator.addr, validator.stake, true, true);
            _stake(validator.addr, validator.stake);
            localTotalStake += validator.stake;
        }
        _totalStake = localTotalStake;
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stake(uint256 amount) external onlyValidator(msg.sender) {
        _stake(msg.sender, amount);
        // slither-disable-next-line events-maths
        _totalStake += amount;
    }

    /**
     * @inheritdoc IStakeManager
     */
    function unstake(uint256 amount) external onlyValidator(msg.sender) {
        _unstake(msg.sender, amount);
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
    function whitelistValidators(address[] calldata validators_) external onlyOwner {
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

    /**
     * @inheritdoc IStakeManager
     */
    function withdraw() external {
        WithdrawalQueue storage queue = _withdrawals[msg.sender];
        (uint256 amount, uint256 newHead) = queue.withdrawable(_epochManager.currentEpochId());
        queue.head = newHead;
        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    // slither-disable-next-line unused-return
    function withdrawable(address account) external view returns (uint256 amount) {
        (amount, ) = _withdrawals[account].withdrawable(_epochManager.currentEpochId());
    }

    /**
     * @inheritdoc IStakeManager
     */
    function pendingWithdrawals(address account) external view returns (uint256) {
        return _withdrawals[account].pending(_epochManager.currentEpochId());
    }

    function _withdrawStake(address validator, address to, uint256 amount) private {
        _withdrawableStakes[validator] -= amount;
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

    function _stake(address validator, uint256 amount) internal {
        _mint(validator, amount);
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        _stakingToken.safeTransferFrom(validator, address(this), amount);
        // calling the library directly once fixes the coverage issue
        // https://github.com/foundry-rs/foundry/issues/4854#issuecomment-1528897219
        validators[validator].stake += amount;
        // slither-disable-next-line reentrancy-events
        emit StakeAdded(validator, amount);
    }

    function _unstake(address validator, uint256 amount) internal {
        _burn(validator, amount);
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

    function _removeStake(address validator, uint256 amount) internal {
        validators[validator].stake -= amount;
        _totalStake -= amount;
        _withdrawableStakes[validator] += amount;
        _withdrawals[validator].append(amount, _epochManager.currentEpochId() + WITHDRAWAL_WAIT_PERIOD);
    }

    function _stakeOf(address validator) internal view returns (uint256 amount) {
        amount = validators[validator].stake;
    }

    function _withdrawableStakeOf(address validator) internal view returns (uint256 amount) {
        amount = _withdrawableStakes[validator];
    }

    /// @dev the epoch number is also the snapshot id
    function _getCurrentSnapshotId() internal view override returns (uint256) {
        return _epochManager.currentEpochId();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        require(from == address(0) || to == address(0), "TRANSFER_FORBIDDEN");
        super._beforeTokenTransfer(from, to, amount);
    }

    function totalSupplyAt(
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IStakeManager) returns (uint256) {
        return super.totalSupplyAt(epochNumber);
    }

    function balanceOfAt(
        address account,
        uint256 epochNumber
    ) public view override(ERC20SnapshotUpgradeable, IStakeManager) returns (uint256) {
        return super.balanceOfAt(account, epochNumber);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[48] private __gap;
}
