// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/bridge/IRootERC1155Predicate.sol";
import "../interfaces/IGateway.sol";
import "../lib/Predicate.sol";

// solhint-disable reason-string
contract RootERC1155Predicate is Predicate, Initializable, ERC1155Holder, IRootERC1155Predicate {
    address public childERC1155Predicate;
    address public destinationTokenTemplate;
    mapping(address => address) public sourceTokenToDestinationToken;

    /**
     * @notice Initialization function for RootERC1155Predicate
     * @param newGateway Address of gateway to send deposit information to
     * @param newChildERC1155Predicate Address of child ERC1155 predicate to communicate with
     * @param newDestinationTokenTemplate Address of child token template to deploy clones of
     * @param newDestinationChainId Chain ID of destination chain
     * @dev Can only be called once.
     */
    function initialize(
        address newGateway,
        address newChildERC1155Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) external initializer {
        _initialize(newGateway, newChildERC1155Predicate, newDestinationTokenTemplate, newDestinationChainId);
    }

    /**
     * @inheritdoc IStateReceiver
     * @notice Function to be used for token withdrawals
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == address(gateway), "RootERC1155Predicate: ONLY_GATEWAY");
        require(sender == childERC1155Predicate, "RootERC1155Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _withdraw(data[32:]);
        } else if (bytes32(data[:32]) == WITHDRAW_BATCH_SIG) {
            _withdrawBatch(data);
        } else {
            revert("RootERC1155Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function deposit(IERC1155MetadataURI rootToken, uint256 tokenId, uint256 amount) external {
        _deposit(rootToken, msg.sender, tokenId, amount);
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function depositTo(IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) external {
        _deposit(rootToken, receiver, tokenId, amount);
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function depositBatch(
        IERC1155MetadataURI rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        require(
            receivers.length == tokenIds.length && receivers.length == amounts.length,
            "RootERC1155Predicate: INVALID_LENGTH"
        );
        _depositBatch(rootToken, receivers, tokenIds, amounts);
    }

    /**
     * @inheritdoc IRootERC1155Predicate
     */
    function mapToken(IERC1155MetadataURI rootToken) public returns (address childToken) {
        require(address(rootToken) != address(0), "RootERC1155Predicate: INVALID_TOKEN");
        require(
            sourceTokenToDestinationToken[address(rootToken)] == address(0),
            "RootERC1155Predicate: ALREADY_MAPPED"
        );

        address childPredicate = childERC1155Predicate;

        childToken = Clones.predictDeterministicAddress(
            destinationTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childPredicate
        );

        sourceTokenToDestinationToken[address(rootToken)] = childToken;

        string memory uri = "";
        // slither does not deal well with try-catch: https://github.com/crytic/slither/issues/982
        // slither-disable-next-line uninitialized-local,unused-return,variable-scope
        try rootToken.uri(0) returns (string memory tokenUri) {
            uri = tokenUri;
        } catch {}

        gateway.sendBridgeMsg(childPredicate, abi.encode(MAP_TOKEN_SIG, rootToken, uri), destinationChainId);
        // slither-disable-next-line reentrancy-events
        emit TokenMapped(address(rootToken), childToken);
    }

    function _deposit(IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        rootToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        gateway.sendBridgeMsg(
            childERC1155Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, tokenId, amount),
            destinationChainId
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155Deposit(address(rootToken), childToken, msg.sender, receiver, tokenId, amount);
        _afterTokenDeposit();
    }

    function _depositBatch(
        IERC1155MetadataURI rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        for (uint256 i = 0; i < tokenIds.length; ) {
            rootToken.safeTransferFrom(msg.sender, address(this), tokenIds[i], amounts[i], "");
            unchecked {
                ++i;
            }
        }

        gateway.sendBridgeMsg(
            childERC1155Predicate,
            abi.encode(DEPOSIT_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds, amounts),
            destinationChainId
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155DepositBatch(address(rootToken), childToken, msg.sender, receivers, tokenIds, amounts);
        _afterTokenDeposit();
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 tokenId, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256, uint256)
        );
        address childToken = sourceTokenToDestinationToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC1155MetadataURI(rootToken).safeTransferFrom(address(this), receiver, tokenId, amount, "");
        // slither-disable-next-line reentrancy-events
        emit ERC1155Withdraw(address(rootToken), childToken, withdrawer, receiver, tokenId, amount);
    }

    function _withdrawBatch(bytes calldata data) private {
        (
            ,
            address rootToken,
            address withdrawer,
            address[] memory receivers,
            uint256[] memory tokenIds,
            uint256[] memory amounts
        ) = abi.decode(data, (bytes32, address, address, address[], uint256[], uint256[]));
        address childToken = sourceTokenToDestinationToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens
        for (uint256 i = 0; i < tokenIds.length; ) {
            IERC1155MetadataURI(rootToken).safeTransferFrom(address(this), receivers[i], tokenIds[i], amounts[i], "");
            unchecked {
                ++i;
            }
        }
        // slither-disable-next-line reentrancy-events
        emit ERC1155WithdrawBatch(address(rootToken), childToken, withdrawer, receivers, tokenIds, amounts);
    }

    function _getChildToken(IERC1155MetadataURI rootToken) private returns (address childToken) {
        childToken = sourceTokenToDestinationToken[address(rootToken)];
        if (childToken == address(0)) childToken = mapToken(IERC1155MetadataURI(rootToken));
        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist
    }

    /**
     * @notice Initialization function for RootERC1155Predicate
     * @param newGateway Address of Gateway contract
     * @param newChildERC1155Predicate Address of child ERC1155 predicate to communicate with
     * @param newDestinationTokenTemplate Address of child token template to deploy clones of
     * @param newDestinationChainId Chain ID of destination chain
     * @dev Can only be called once.
     */
    function _initialize(
        address newGateway,
        address newChildERC1155Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) internal {
        super._initialize(newGateway, newDestinationChainId);
        require(
            newChildERC1155Predicate != address(0) && newDestinationTokenTemplate != address(0),
            "RootERC1155Predicate: BAD_INITIALIZATION"
        );
        childERC1155Predicate = newChildERC1155Predicate;
        destinationTokenTemplate = newDestinationTokenTemplate;
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code

    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
