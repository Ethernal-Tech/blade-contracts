// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RootERC1155Predicate} from "../bridge/RootERC1155Predicate.sol";
import {AccessList} from "../lib/AccessList.sol";

/**
    @title RootMintableERC1155PredicateAccessList
    @author Polygon Technology (@QEDK)
    @notice Enables child-chain origin ERC1155 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain
 */
// solhint-disable reason-string
contract RootMintableERC1155PredicateAccessList is AccessList, RootERC1155Predicate {
    function initialize(
        address newGateway,
        address newChildERC1155Predicate,
        address newTokenTemplate,
        uint256 newDestinationChainId,
        bool newUseAllowList,
        bool newUseBlockList,
        address newOwner
    ) public virtual onlySystemCall initializer {
        _initialize(newGateway, newChildERC1155Predicate, newTokenTemplate, newDestinationChainId);
        _initializeAccessList(newUseAllowList, newUseBlockList);
        _transferOwnership(newOwner);
    }

    function _beforeTokenDeposit() internal virtual override {
        _checkAccessList();
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
