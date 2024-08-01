// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/blade/IChildERC1155Predicate.sol";
import "../interfaces/blade/IChildERC1155.sol";
import "../interfaces/IGateway.sol";

/**
    @title ChildERC1155Predicate
    @author Polygon Technology (@QEDK, @wschwab)
    @notice Enables ERC1155 token deposits and withdrawals across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract ChildERC1155Predicate is IChildERC1155Predicate, Initializable {
    IGateway public gateway;
    address public rootERC1155Predicate;
    address public destinationTokenTemplate;
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");

    mapping(address => address) public rootTokenToChildToken;

    event ERC1155Deposit(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId,
        uint256 amount
    );
    event ERC1155DepositBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event ERC1155Withdraw(
        address indexed rootToken,
        address indexed childToken,
        address sender,
        address indexed receiver,
        uint256 tokenId,
        uint256 amount
    );
    event ERC1155WithdrawBatch(
        address indexed rootToken,
        address indexed childToken,
        address indexed sender,
        address[] receivers,
        uint256[] tokenIds,
        uint256[] amounts
    );
    event TokenMapped(address indexed rootToken, address indexed childToken);

    modifier onlyValidToken(IChildERC1155 childToken) {
        require(_verifyContract(childToken), "ChildERC1155Predicate: NOT_CONTRACT");
        _;
    }

    /**
     * @notice Initialization function for ChildERC1155Predicate
     * @param newGateway Address of gateway contract
     * @param newRootERC1155Predicate Address of root ERC1155 predicate to communicate with
     * @param newDestinationTokenTemplate Address of destination token implementation to deploy clones of
     * @dev Can only be called once.
     */
    function initialize(
        address newGateway,
        address newRootERC1155Predicate,
        address newDestinationTokenTemplate
    ) public virtual initializer {
        _initialize(newGateway, newRootERC1155Predicate, newDestinationTokenTemplate);
    }

    /**
     * @notice Function to be used for token deposits
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     * @dev Can be extended to include other signatures for more functionality
     */
    function onStateReceive(uint256 /* id */, address sender, bytes calldata data) external {
        require(msg.sender == address(gateway), "ChildERC1155Predicate: ONLY_GATEWAY");
        require(sender == rootERC1155Predicate, "ChildERC1155Predicate: ONLY_ROOT_PREDICATE");

        if (bytes32(data[:32]) == DEPOSIT_SIG) {
            _beforeTokenDeposit();
            _deposit(data[32:]);
            _afterTokenDeposit();
        } else if (bytes32(data[:32]) == DEPOSIT_BATCH_SIG) {
            _beforeTokenDeposit();
            _depositBatch(data);
            _afterTokenDeposit();
        } else if (bytes32(data[:32]) == MAP_TOKEN_SIG) {
            _mapToken(data);
        } else {
            revert("ChildERC1155Predicate: INVALID_SIGNATURE");
        }
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to themselves on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param tokenId Index of the NFT to withdraw
     * @param amount Amount of the NFT to withdraw
     */
    function withdraw(IChildERC1155 childToken, uint256 tokenId, uint256 amount) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, msg.sender, tokenId, amount);
        _afterTokenWithdraw();
    }

    /**
     * @notice Function to withdraw tokens from the withdrawer to another address on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receiver Address of the receiver on the root chain
     * @param tokenId Index of the NFT to withdraw
     * @param amount Amount of NFT to withdraw
     */
    function withdrawTo(IChildERC1155 childToken, address receiver, uint256 tokenId, uint256 amount) external {
        _beforeTokenWithdraw();
        _withdraw(childToken, receiver, tokenId, amount);
        _afterTokenWithdraw();
    }

    /**
     * @notice Function to batch withdraw tokens from the withdrawer to other addresses on the root chain
     * @param childToken Address of the child token being withdrawn
     * @param receivers Addresses of the receivers on the root chain
     * @param tokenIds indices of the NFTs to withdraw
     * @param amounts Amounts of NFTs to withdraw
     */
    function withdrawBatch(
        IChildERC1155 childToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        _beforeTokenWithdraw();
        _withdrawBatch(childToken, receivers, tokenIds, amounts);
        _afterTokenWithdraw();
    }

    /**
     * @notice Internal initialization function for ChildERC1155Predicate
     * @param newGateway Address of gateway contract
     * @param newRootERC1155Predicate Address of root ERC1155 predicate to communicate with
     * @param newDestinationTokenTemplate Address of destination token implementation to deploy clones of
     * @dev Can be called multiple times.
     */
    function _initialize(
        address newGateway,
        address newRootERC1155Predicate,
        address newDestinationTokenTemplate
    ) internal {
        require(
            newGateway != address(0) &&
                newRootERC1155Predicate != address(0) &&
                newDestinationTokenTemplate != address(0),
            "ChildERC1155Predicate: BAD_INITIALIZATION"
        );
        gateway = IGateway(newGateway);
        rootERC1155Predicate = newRootERC1155Predicate;
        destinationTokenTemplate = newDestinationTokenTemplate;
    }

    // solhint-disable no-empty-blocks
    // slither-disable-start dead-code
    function _beforeTokenDeposit() internal virtual {}

    function _beforeTokenWithdraw() internal virtual {}

    function _afterTokenDeposit() internal virtual {}

    function _afterTokenWithdraw() internal virtual {}

    // slither-disable-end dead-code

    function _withdraw(
        IChildERC1155 childToken,
        address receiver,
        uint256 tokenId,
        uint256 amount
    ) private onlyValidToken(childToken) {
        address rootToken = childToken.rootToken();

        require(rootTokenToChildToken[rootToken] == address(childToken), "ChildERC1155Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(childToken.burn(msg.sender, tokenId, amount), "ChildERC1155Predicate: BURN_FAILED");
        gateway.sendBridgeMsg(
            rootERC1155Predicate,
            abi.encode(WITHDRAW_SIG, rootToken, msg.sender, receiver, tokenId, amount)
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155Withdraw(rootToken, address(childToken), msg.sender, receiver, tokenId, amount);
    }

    function _withdrawBatch(
        IChildERC1155 childToken,
        address[] calldata receivers,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) private onlyValidToken(childToken) {
        address rootToken = childToken.rootToken();

        require(rootTokenToChildToken[rootToken] == address(childToken), "ChildERC1155Predicate: UNMAPPED_TOKEN");
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(childToken.predicate() == address(this));

        require(
            receivers.length == tokenIds.length && tokenIds.length == amounts.length,
            "ChildERC1155Predicate: INVALID_LENGTH"
        );

        require(childToken.burnBatch(msg.sender, tokenIds, amounts), "ChildERC1155Predicate: BURN_FAILED");

        gateway.sendBridgeMsg(
            rootERC1155Predicate,
            abi.encode(WITHDRAW_BATCH_SIG, rootToken, msg.sender, receivers, tokenIds, amounts)
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155WithdrawBatch(rootToken, address(childToken), msg.sender, receivers, tokenIds, amounts);
    }

    function _deposit(bytes calldata data) private {
        (address depositToken, address depositor, address receiver, uint256 tokenId, uint256 amount) = abi.decode(
            data,
            (address, address, address, uint256, uint256)
        );

        IChildERC1155 childToken = IChildERC1155(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildERC1155Predicate: UNMAPPED_TOKEN");
        // a mapped token should always pass specifications
        assert(_verifyContract(childToken));

        address rootToken = IChildERC1155(childToken).rootToken();

        // a mapped child token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC1155(childToken).predicate() == address(this));
        require(IChildERC1155(childToken).mint(receiver, tokenId, amount), "ChildERC1155Predicate: MINT_FAILED");
        // slither-disable-next-line reentrancy-events
        emit ERC1155Deposit(depositToken, address(childToken), depositor, receiver, tokenId, amount);
    }

    function _depositBatch(bytes calldata data) private {
        (
            ,
            address depositToken,
            address depositor,
            address[] memory receivers,
            uint256[] memory tokenIds,
            uint256[] memory amounts
        ) = abi.decode(data, (bytes32, address, address, address[], uint256[], uint256[]));

        IChildERC1155 childToken = IChildERC1155(rootTokenToChildToken[depositToken]);

        require(address(childToken) != address(0), "ChildERC1155Predicate: UNMAPPED_TOKEN");
        // a mapped token should always pass specifications
        assert(_verifyContract(childToken));

        address rootToken = IChildERC1155(childToken).rootToken();

        // a mapped child token should match deposited token
        assert(rootToken == depositToken);
        // a mapped token should never have root token unset
        assert(rootToken != address(0));
        // a mapped token should never have predicate unset
        assert(IChildERC1155(childToken).predicate() == address(this));
        require(
            IChildERC1155(childToken).mintBatch(receivers, tokenIds, amounts),
            "ChildERC1155Predicate: MINT_FAILED"
        );
        // slither-disable-next-line reentrancy-events
        emit ERC1155DepositBatch(depositToken, address(childToken), depositor, receivers, tokenIds, amounts);
    }

    /**
     * @notice Function to be used for mapping a root token to a child token
     * @dev Allows for 1-to-1 mappings for any root token to a child token
     */
    function _mapToken(bytes calldata data) private {
        (, address rootToken, string memory uri_) = abi.decode(data, (bytes32, address, string));
        assert(rootToken != address(0)); // invariant since root predicate performs the same check
        assert(rootTokenToChildToken[rootToken] == address(0)); // invariant since root predicate performs the same check
        IChildERC1155 childToken = IChildERC1155(
            Clones.cloneDeterministic(destinationTokenTemplate, keccak256(abi.encodePacked(rootToken)))
        );
        rootTokenToChildToken[rootToken] = address(childToken);
        childToken.initialize(rootToken, uri_);

        // slither-disable-next-line reentrancy-events
        emit TokenMapped(rootToken, address(childToken));
    }

    // slither does not handle try-catch blocks correctly
    // slither-disable-next-line unused-return
    function _verifyContract(IChildERC1155 childToken) private view returns (bool) {
        if (address(childToken).code.length == 0) {
            return false;
        }
        // slither-disable-next-line uninitialized-local,variable-scope
        try childToken.supportsInterface(0xd9b67a26) returns (bool support) {
            return support;
        } catch {
            return false;
        }
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
