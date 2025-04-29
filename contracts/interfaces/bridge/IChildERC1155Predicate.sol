// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IChildERC1155.sol";
import "./IReceiver.sol";

interface IChildERC1155Predicate is IReceiver {
    function initialize(
        address newGateway,
        address newRootERC721Predicate,
        address newDestinationTokenTemplate,
        uint256 newDestinationChainId
    ) external;

    function withdraw(IChildERC1155 childToken, uint256 tokenId, uint256 amount) external;

    function withdrawTo(IChildERC1155 childToken, address receiver, uint256 tokenId, uint256 amount) external;
}
