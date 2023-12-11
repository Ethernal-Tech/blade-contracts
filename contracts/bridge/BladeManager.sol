// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/GenesisLib.sol";
import "../interfaces/bridge/IBladeManager.sol";
import "../interfaces/bridge/IRootERC20Predicate.sol";

contract BladeManager is IBladeManager, Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;
    using GenesisLib for GenesisSet;

    IRootERC20Predicate private _rootERC20Predicate;
    GenesisSet private _genesis;

    function initialize(address newRootERC20Predicate, GenesisAccount[] calldata genesisValidators) public initializer {
        require(newRootERC20Predicate != address(0), "INVALID_INPUT");

        _rootERC20Predicate = IRootERC20Predicate(newRootERC20Predicate);

        uint256 length = genesisValidators.length;
        for (uint256 i = 0; i < length; ++i) {
            _genesis.insert(genesisValidators[i].addr, genesisValidators[i].amountOfTokens);
        }

        __Ownable2Step_init();
    }

    /**
     * @inheritdoc IBladeManager
     */
    function finalizeGenesis() external onlyOwner {
        // calling the library directly once fixes the coverage issue
        // https://github.com/foundry-rs/foundry/issues/4854#issuecomment-1528897219
        GenesisLib.finalize(_genesis);
        emit GenesisFinalized(_genesis.set().length);
    }

    /**
     * @inheritdoc IBladeManager
     */
    function genesisSet() external view returns (GenesisAccount[] memory) {
        return _genesis.set();
    }

    /**
     *
     * @inheritdoc IBladeManager
     */
    function addGenesisBalance(uint256 amount) external {
        require(amount > 0, "BladeManager: INVALID_AMOUNT");
        if (address(_rootERC20Predicate) == address(0)) {
            revert Unauthorized("BladeManager: UNDEFINED_ROOT_ERC20_PREDICATE");
        }

        IERC20 nativeTokenRoot = IERC20(_rootERC20Predicate.nativeTokenRoot());
        if (address(nativeTokenRoot) == address(0)) {
            revert Unauthorized("BladeManager: UNDEFINED_NATIVE_TOKEN_ROOT");
        }
        require(!_genesis.completed(), "BladeManager: CHILD_CHAIN_IS_LIVE");

        // we need to track EOAs as well in the genesis set, in order to be able to query genesisBalances mapping
        _genesis.insert(msg.sender, amount);

        // lock native tokens on the root erc20 predicate
        nativeTokenRoot.safeTransferFrom(msg.sender, address(_rootERC20Predicate), amount);

        // slither-disable-next-line reentrancy-events
        emit GenesisBalanceAdded(msg.sender, amount);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[48] private __gap;
}
