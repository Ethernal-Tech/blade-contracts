// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IGateway {
    function sendBridgeMsg(address receiver, bytes calldata data) external;
}
