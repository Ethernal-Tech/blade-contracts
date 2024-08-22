// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/bridge/IRootERC721Predicate.sol";
import "../interfaces/IGateway.sol";
import "../lib/Predicate.sol";

// solhint-disable reason-string
contract RootERC721Predicate is Predicate, Initializable, ERC721Holder, IRootERC721Predicate {
    address public childERC721Predicate;
    address public destinationTokenTemplate;
    mapping(address => address) public sourceTokenToDestinationToken;

    /**
     * @notice Initialization function for RootERC721Predicate
     * @param newGateway Address of gateway contract
     * @param newChildERC721Predicate Address of child ERC721 predicate to communicate with
     * @param newDestinationTokenTemplate Address of destination token implementation to deploy clones of
     * @param newDestinationChainId Chain ID of destination chain
     * @dev Can only be called once.
     */
    function initialize(
        address newGateway,
        address newChildERC721Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) external initializer {
        _initialize(newGateway, newChildERC721Predicate, newDestinationTokenTemplate, newDestinationChainId);
    }

    /**
     * @inheritdoc IStateReceiver
     * @notice Function to be used for token withdrawals
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == address(gateway), "RootERC721Predicate: ONLY_GATEWAY");
        require(sender == childERC721Predicate, "RootERC721Predicate: ONLY_CHILD_PREDICATE");

        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            _withdraw(data[32:]);
        } else if (bytes32(data[:32]) == WITHDRAW_BATCH_SIG) {
            _withdrawBatch(data);
        } else {
            revert("RootERC721Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @inheritdoc IRootERC721Predicate
     */
    function deposit(IERC721Metadata rootToken, uint256 tokenId) external {
        _deposit(rootToken, msg.sender, tokenId);
    }

    /**
     * @inheritdoc IRootERC721Predicate
     */
    function depositTo(IERC721Metadata rootToken, address receiver, uint256 tokenId) external {
        _deposit(rootToken, receiver, tokenId);
    }

    /**
     * @inheritdoc IRootERC721Predicate
     */
    function depositBatch(
        IERC721Metadata rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) external {
        require(receivers.length == tokenIds.length, "RootERC721Predicate: INVALID_LENGTH");
        _depositBatch(rootToken, receivers, tokenIds);
    }

    /**
     * @inheritdoc IRootERC721Predicate
     */
    function mapToken(IERC721Metadata rootToken) public returns (address) {
        require(address(rootToken) != address(0), "RootERC721Predicate: INVALID_TOKEN");
        require(sourceTokenToDestinationToken[address(rootToken)] == address(0), "RootERC721Predicate: ALREADY_MAPPED");

        address childPredicate = childERC721Predicate;

        address childToken = Clones.predictDeterministicAddress(
            destinationTokenTemplate,
            keccak256(abi.encodePacked(rootToken)),
            childPredicate
        );

        sourceTokenToDestinationToken[address(rootToken)] = childToken;

        gateway.sendBridgeMsg(
            childPredicate,
            abi.encode(MAP_TOKEN_SIG, rootToken, rootToken.name(), rootToken.symbol()),
            destinationChainId
        );
        // slither-disable-next-line reentrancy-events
        emit TokenMapped(address(rootToken), childToken);
        return childToken;
    }

    function _deposit(IERC721Metadata rootToken, address receiver, uint256 tokenId) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        rootToken.safeTransferFrom(msg.sender, address(this), tokenId);

        gateway.sendBridgeMsg(
            childERC721Predicate,
            abi.encode(DEPOSIT_SIG, rootToken, msg.sender, receiver, tokenId),
            destinationChainId
        );
        // slither-disable-next-line reentrancy-events
        emit ERC721Deposit(address(rootToken), childToken, msg.sender, receiver, tokenId);
        _afterTokenDeposit();
    }

    function _depositBatch(
        IERC721Metadata rootToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds
    ) private {
        _beforeTokenDeposit();
        address childToken = _getChildToken(rootToken);

        for (uint256 i = 0; i < tokenIds.length; ) {
            rootToken.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        gateway.sendBridgeMsg(
            childERC721Predicate,
            abi.encode(DEPOSIT_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds),
            destinationChainId
        );
        // slither-disable-next-line reentrancy-events
        emit ERC721DepositBatch(address(rootToken), childToken, msg.sender, receivers, tokenIds);
        _afterTokenDeposit();
    }

    function _withdraw(bytes calldata data) private {
        (address rootToken, address withdrawer, address receiver, uint256 tokenId) = abi.decode(
            data,
            (address, address, address, uint256)
        );
        address childToken = sourceTokenToDestinationToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens

        IERC721Metadata(rootToken).safeTransferFrom(address(this), receiver, tokenId);
        // slither-disable-next-line reentrancy-events
        emit ERC721Withdraw(address(rootToken), childToken, withdrawer, receiver, tokenId);
    }

    function _withdrawBatch(bytes calldata data) private {
        (, address rootToken, address withdrawer, address[] memory receivers, uint256[] memory tokenIds) = abi.decode(
            data,
            (bytes32, address, address, address[], uint256[])
        );
        address childToken = sourceTokenToDestinationToken[rootToken];
        assert(childToken != address(0)); // invariant because child predicate should have already mapped tokens
        for (uint256 i = 0; i < tokenIds.length; ) {
            IERC721Metadata(rootToken).safeTransferFrom(address(this), receivers[i], tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        // slither-disable-next-line reentrancy-events
        emit ERC721WithdrawBatch(address(rootToken), childToken, withdrawer, receivers, tokenIds);
    }

    function _getChildToken(IERC721Metadata rootToken) private returns (address childToken) {
        childToken = sourceTokenToDestinationToken[address(rootToken)];
        if (childToken == address(0)) childToken = mapToken(IERC721Metadata(rootToken));
        assert(childToken != address(0)); // invariant because we map the token if mapping does not exist
    }

    // solhint-disable no-empty-blocks

    // slither-disable-start dead-code

    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    /**
     * @notice Initialization function for RootERC721Predicate
     * @param newGateway Address of gateway contract
     * @param newChildERC721Predicate Address of child ERC721 predicate to communicate with
     * @param newDestinationTokenTemplate Address of destination token implementation to deploy clones of
     * @param newDestinationChainId Chain ID of destination chain
     * @dev Can only be called once.
     */
    function _initialize(
        address newGateway,
        address newChildERC721Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) internal {
        super._initialize(newGateway, newDestinationChainId);
        require(
            newGateway != address(0) &&
                newChildERC721Predicate != address(0) &&
                newDestinationTokenTemplate != address(0),
            "RootERC721Predicate: BAD_INITIALIZATION"
        );
        gateway = IGateway(newGateway);
        childERC721Predicate = newChildERC721Predicate;
        destinationTokenTemplate = newDestinationTokenTemplate;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
