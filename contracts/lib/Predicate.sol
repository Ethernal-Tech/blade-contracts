// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Predicate is OwnableUpgradeable {
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    bytes32 public constant ROLLBACK_SIG = keccak256("ROLLBACK");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");

    mapping(address => bool) trustedRelayers;

    function predicateInit() internal onlyInitializing {
        __Ownable_init();
    }

    function predicateInit(address owner) internal onlyInitializing {
        __Ownable_init();
        transferOwnership(owner);
    } 

    function addTrustedRelayer(address relayer) external onlyOwner {
        require(msg.sender == address(this), "Predicate: INVALID_SENDER");
        trustedRelayers[relayer] = true;
    }

    function removeTrustedRelayer(address relayer) external onlyOwner {
        require(msg.sender == address(this), "Predicate: INVALID_SENDER");
        trustedRelayers[relayer] = false;
    }
}