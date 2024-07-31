// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IChildERC1155.sol";
import "./IStateReceiver.sol";

interface IChildERC1155Predicate is IStateReceiver {
    function initialize(
        address newGateway,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) external;

    function withdraw(IChildERC1155 childToken, uint256 tokenId, uint256 amount) external;

    function withdrawTo(IChildERC1155 childToken, address receiver, uint256 tokenId, uint256 amount) external;
}
