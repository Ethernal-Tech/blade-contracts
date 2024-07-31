// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IStateReceiver.sol";
import "./IChildERC20.sol";

interface IChildERC20Predicate is IStateReceiver {
    function initialize(
        address newGateway,
        address newStateReceiver,
        address newRootERC20Predicate,
        address newChildTokenTemplate,
        address newNativeTokenRootAddress
    ) external;

    function withdraw(IChildERC20 childToken, uint256 amount) external;

    function withdrawTo(IChildERC20 childToken, address receiver, uint256 amount) external;
}
