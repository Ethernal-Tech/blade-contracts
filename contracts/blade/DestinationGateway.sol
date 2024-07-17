// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./BaseBridgeGateway.sol";

contract DestinationGateway is BaseBridgeGateway {
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public lastCommittedId;

    mapping(uint256 => bool) public processedEvents;

    event BridgeMessageResult(uint256 indexed counter, bool indexed status, bytes message);

    /**
     * @notice receives the batch of messages and executes them
     * @param batch batch of messages
     */
    function receive(BridgeMessageBatch calldata batch) public {
        _verifyBatch(batch);

        bytes memory hash = abi.encode(keccak256(abi.encode(batch)));
        verifySignature(bls.hashToPoint(DOMAIN, hash), batch.signature, batch.bitmap);

        uint256 length = batch.messages.length;
        for (uint256 i = 0; i < length; ) {
            BridgeMessage memory commitment = batch.messages[i];

            _executeBridgeMessage(objs[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    function _verifyBatch(BridgeMessageBatch calldata batch) private pure {
        require(batch.messages.length > 0, "EMPTY_BATCH");

        uint256 sourceChainId = batch.messages[0].sourceChainId;
        uint256 destinationChainId = block.chainid;
        for (uint256 i = 0; i < batch.messages.length; ++i) {
            BridgeMessage memory message = batch.messages[i];
            require(message.sourceChainId == sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
        }
    }

    function _executeBridgeMessage(BridgeMessage calldata message) private {
        require(!processedEvents[obj.id], "DestinationGateway: BRIDGE_MESSAGE_IS_PROCESSED");
        // Skip transaction if client has added flag, or receiver has no code
        if (obj.receiver.code.length == 0) {
            emit BridgeMessageResult(obj.id, false, "");
            return;
        }

        processedEvents[obj.id] = true;

        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-no-eth
        (bool success, bytes memory returnData) = obj.receiver.call(
            abi.encodeWithSignature("onStateReceive(uint256,address,bytes)", obj.id, obj.sender, obj.data)
        );

        // if bridge message fails, revert flag
        if (!success) processedEvents[obj.id] = false;

        // emit a ResultEvent indicating whether invocation of bridge message was successful or not
        // slither-disable-next-line reentrancy-events
        emit BridgeMessageResult(obj.id, success, returnData);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}