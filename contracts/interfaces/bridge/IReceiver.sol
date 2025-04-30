// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IReceiver {
    /**
     * @notice Called by gateway when state is received from source chain
     * @param sender Address of the sender on the child chain
     * @param data Data sent by the sender
     */
    function onMsgReceive(uint256 id, address sender, bytes calldata data) external;

    /**
     * @notice Called by gateway when state is received from source chain
     * @param sender Address of the sender on the root chain
     * @param data Data sent by the sender
     */
    function onMsgRollback(uint256 id, address sender, bytes calldata data) external;
}
