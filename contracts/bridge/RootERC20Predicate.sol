// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/bridge/IRootERC20Predicate.sol";
import "../interfaces/IGateway.sol";
import "../lib/Predicate.sol";

// solhint-disable reason-string
contract RootERC20Predicate is Predicate, Initializable, IRootERC20Predicate {
    using SafeERC20 for IERC20Metadata;

    address public childERC20Predicate;
    address public destinationTokenTemplate;
    mapping(address => address) public sourceTokenToDestinationToken;
    address public nativeTokenRoot;

    /**
     * @notice Initialization function for RootERC20Predicate
     * @param newGateway Address of gateway contract
     * @param newChildERC20Predicate Address of child ERC20 predicate to communicate with
     * @param newDestinationTokenTemplate Address of destination token implementation to deploy clones of
     * @param newNativeTokenRoot Address of the native token
     * @param newDestinationChainId Chain ID of destination chain
     * @dev Can only be called once.
     */
    function initialize(
        address newGateway,
        address newChildERC20Predicate,
        address newDestinationTokenTemplate,
        address newNativeTokenRoot,
        uint256 newDestinationChainId
    ) external initializer {
        _initialize(
            newGateway,
            newChildERC20Predicate,
            newDestinationTokenTemplate,
            newNativeTokenRoot,
            newDestinationChainId
        );
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code
    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    /**
     * @inheritdoc IStateReceiver
     * @notice Function to be used for token withdrawals
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == address(gateway), "RootERC20Predicate: ONLY_GATEWAY");
        require(sender == childERC20Predicate, "RootERC20Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _withdraw(data[32:]);
        } else {
            revert("RootERC20Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @inheritdoc IRootERC20Predicate
     */
    function deposit(IERC20Metadata rootToken, uint256 amount) external {
        _deposit(rootToken, msg.sender, amount);
    }

    /**
     * @inheritdoc IRootERC20Predicate
     */
    function depositTo(IERC20Metadata rootToken, address receiver, uint256 amount) external {
        _deposit(rootToken, receiver, amount);
    }

    /**
     * @inheritdoc IRootERC20Predicate
     */
    function mapToken(IERC20Metadata rootToken) public returns (address) {
        require(address(rootToken) != address(0), "RootERC20Predicate: INVALID_TOKEN");
        require(sourceTokenToDestinationToken[address(rootToken)] == address(0), "RootERC20Predicate: ALREADY_MAPPED");

        address childPredicate = childERC20Predicate;

        address childToken = Clones.predictDeterministicAddress(
            destinationTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childPredicate
        );

        sourceTokenToDestinationToken[address(rootToken)] = childToken;

        gateway.sendBridgeMsg(
            childPredicate,
            abi.encode(MAP_TOKEN_SIG, rootToken, rootToken.name(), rootToken.symbol(), rootToken.decimals()),
            destinationChainId
        );
        // slither-disable-next-line reentrancy-events
        emit TokenMapped(address(rootToken), childToken);

        return childToken;
    }

    function _deposit(IERC20Metadata rootToken, address receiver, uint256 amount) private {
        _beforeTokenDeposit();
        address childToken = sourceTokenToDestinationToken[address(rootToken)];

        if (childToken == address(0)) {
            childToken = mapToken(rootToken);
        }

        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist

        rootToken.safeTransferFrom(msg.sender, address(this), amount);

        gateway.sendBridgeMsg(
            childERC20Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, amount),
            destinationChainId
        );
        // slither-disable-next-line reentrancy-events
        emit ERC20Deposit(address(rootToken), childToken, msg.sender, receiver, amount);

        _afterTokenDeposit();
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        address childToken = sourceTokenToDestinationToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC20Metadata(rootToken).safeTransfer(receiver, amount);
        // slither-disable-next-line reentrancy-events
        emit ERC20Withdraw(address(rootToken), childToken, withdrawer, receiver, amount);
    }

    /**
     * @notice Internal initialization function for RootERC20Predicate
     * @param newGateway Address of Gateway contract
     * @param newChildERC20Predicate Address of destination ERC20 predicate to communicate with
     * @param newDestinationTokenTemplate Address of destination token implementation to deploy clones of
     * @param newNativeTokenRoot Address of rootchain token that represents the native token
     * @param newDestinationChainId Chain ID of destination chain
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newGateway,
        address newChildERC20Predicate,
        address newDestinationTokenTemplate,
        address newNativeTokenRoot,
        uint256 newDestinationChainId
    ) internal {
        super._initialize(newGateway, newDestinationChainId);
        require(
            newChildERC20Predicate != address(0) && newDestinationTokenTemplate != address(0),
            "RootERC20Predicate: BAD_INITIALIZATION"
        );
        childERC20Predicate = newChildERC20Predicate;
        destinationTokenTemplate = newDestinationTokenTemplate;
        if (newNativeTokenRoot != address(0)) {
            nativeTokenRoot = newNativeTokenRoot;
            sourceTokenToDestinationToken[nativeTokenRoot] = 0x0000000000000000000000000000000000000106;
            emit TokenMapped(nativeTokenRoot, 0x0000000000000000000000000000000000000106);
        }
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
