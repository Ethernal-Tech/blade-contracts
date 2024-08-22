// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../interfaces/IGateway.sol";

abstract contract Predicate {
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");

    IGateway public gateway;
    uint256 public destinationChainId;

    function _initialize(address newGateway, uint256 newDestinationChainId) internal {
        require(
            newGateway != address(0) && newDestinationChainId != 0, 
            "Predicate: BAD_INITIALIZATION"
        );

        gateway = IGateway(newGateway);
        destinationChainId = newDestinationChainId;
    }
}