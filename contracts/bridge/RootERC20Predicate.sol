// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/bridge/IRootERC20Predicate.sol";
import "../interfaces/IGateway.sol";

// solhint-disable reason-string
contract RootERC20Predicate is Initializable, IRootERC20Predicate {
    using SafeERC20 for IERC20Metadata;

    IGateway public gateway;
    address public exitHelper;
    address public childERC20Predicate;
    address public childTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    mapping(address => address) public rootTokenToChildToken;
    address public nativeTokenRoot;

    /**
     * @notice Initialization function for RootERC20Predicate
     * @param newGateway Address of gateway to send deposit information to
     * @param newExitHelper Address of ExitHelper to receive withdrawal information from
     * @param newChildERC20Predicate Address of child ERC20 predicate to communicate with
     * @dev Can only be called once.
     */
    function initialize(
        address newGateway,
        address newExitHelper,
        address newChildERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRoot
    ) external initializer {
        _initialize(newGateway, newExitHelper, newChildERC20Predicate, newChildTokenTemplate, newNativeTokenRoot);
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code
    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    /**
     * @inheritdoc IL2StateReceiver
     * @notice Function to be used for token withdrawals
     * @dev Can be extended to include other signatures for more functionality
     */
    function onL2StateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == exitHelper, "RootERC20Predicate: ONLY_EXIT_HELPER");
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
        require(rootTokenToChildToken[address(rootToken)] == address(0), "RootERC20Predicate: ALREADY_MAPPED");

        address childPredicate = childERC20Predicate;

        address childToken = Clones.predictDeterministicAddress(
            childTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childPredicate
        );

        rootTokenToChildToken[address(rootToken)] = childToken;

        gateway.sendBridgeMsg(
            childPredicate,
            abi.encode(MAP_TOKEN_SIG, rootToken, rootToken.name(), rootToken.symbol(), rootToken.decimals())
        );
        // slither-disable-next-line reentrancy-events
        emit TokenMapped(address(rootToken), childToken);

        return childToken;
    }

    function _deposit(IERC20Metadata rootToken, address receiver, uint256 amount) private {
        _beforeTokenDeposit();
        address childToken = rootTokenToChildToken[address(rootToken)];

        if (childToken == address(0)) {
            childToken = mapToken(rootToken);
        }

        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist

        rootToken.safeTransferFrom(msg.sender, address(this), amount);

        gateway.sendBridgeMsg(childERC20Predicate, abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, amount));
        // slither-disable-next-line reentrancy-events
        emit ERC20Deposit(address(rootToken), childToken, msg.sender, receiver, amount);

        _afterTokenDeposit();
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        address childToken = rootTokenToChildToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC20Metadata(rootToken).safeTransfer(receiver, amount);
        // slither-disable-next-line reentrancy-events
        emit ERC20Withdraw(address(rootToken), childToken, withdrawer, receiver, amount);
    }

    /**
     * @notice Internal initialization function for RootERC20Predicate
     * @param newGateway Address of Gateway contract
     * @param newExitHelper Address of ExitHelper to receive deposit information from
     * @param newChildERC20Predicate Address of destination ERC20 predicate to communicate with
     * @param newChildTokenTemplate Address of child token implementation to deploy clones of
     * @param newNativeTokenRoot Address of rootchain token that represents the native token
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newGateway,
        address newExitHelper,
        address newChildERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRoot
    ) internal {
        require(
            newGateway != address(0) &&
                newExitHelper != address(0) &&
                newChildERC20Predicate != address(0) &&
                newChildTokenTemplate != address(0),
            "RootERC20Predicate: BAD_INITIALIZATION"
        );
        gateway = IGateway(newGateway);
        exitHelper = newExitHelper;
        childERC20Predicate = newChildERC20Predicate;
        childTokenTemplate = newChildTokenTemplate;
        if (newNativeTokenRoot != address(0)) {
            nativeTokenRoot = newNativeTokenRoot;
            rootTokenToChildToken[nativeTokenRoot] = 0x0000000000000000000000000000000000001010;
            emit TokenMapped(nativeTokenRoot, 0x0000000000000000000000000000000000001010);
        }
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
