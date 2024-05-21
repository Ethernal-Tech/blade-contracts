// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

abstract contract Predicate is Ownable2StepUpgradeable {
    bytes32 public constant DEPOSIT_SIG = keccak256("DEPOSIT");
    bytes32 public constant WITHDRAW_SIG = keccak256("WITHDRAW");
    bytes32 public constant MAP_TOKEN_SIG = keccak256("MAP_TOKEN");
    bytes32 public constant ROLLBACK_SIG = keccak256("ROLLBACK");
    bytes32 public constant DEPOSIT_BATCH_SIG = keccak256("DEPOSIT_BATCH");
    bytes32 public constant WITHDRAW_BATCH_SIG = keccak256("WITHDRAW_BATCH");

    mapping(address => bool) trustedRelayers;

    function __Predicate_init() internal onlyInitializing {
        __Ownable2Step_init();
    }

    function __Predicate_init(address owner) internal onlyInitializing {
        __Ownable2Step_init();
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