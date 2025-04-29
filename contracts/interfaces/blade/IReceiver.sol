// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IReceiver {
    function onMsgReceive(uint256 counter, address sender, bytes calldata data) external;

    function onMsgRollback(uint256 id, address sender, bytes calldata data) external;
}
