// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IChildERC721.sol";
import "./IStateReceiver.sol";

interface IChildERC721Predicate is IStateReceiver {
    function initialize(
        address newGateway,
        address newStateReceiver,
        address newRootERC721Predicate,
        address newChildTokenTemplate
    ) external;

    function withdraw(IChildERC721 childToken, uint256 tokenId) external;

    function withdrawTo(IChildERC721 childToken, address receiver, uint256 tokenId) external;

    function withdrawBatch(IChildERC721 childToken, address[] calldata receivers, uint256[] calldata tokenIds) external;
}
