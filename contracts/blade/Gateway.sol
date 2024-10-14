// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ValidatorSetStorage.sol";
import "../interfaces/IGateway.sol";
import "../lib/Merkle.sol";

contract Gateway is ValidatorSetStorage, IGateway {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;

    /// @custom:security write-protection="onlySystemCall()"
    // slither-disable-next-line protected-vars
    mapping(uint256 => bool) public processedEvents;

    event BridgeMessageResult(
        uint256 indexed counter,
        bool indexed status,
        uint256 sourceChainID,
        uint256 destinationChainID,
        bytes message
    );

    event BridgeMsg(
        uint256 indexed id,
        address indexed sender,
        address indexed receiver,
        uint256 sourceChainId,
        uint256 destinationChainId,
        bytes data
    );

    /**
     *
     * @notice Generates sync state event based on receiver and data.
     * Anyone can call this method to emit an event. Receiver on Polygon should add check based on sender.
     *
     * @param receiver Receiver address on Polygon chain
     * @param data Data to send on Polygon chain
     * @param destinationChainId Chain id of destination chain
     *
     */
    function sendBridgeMsg(address receiver, bytes calldata data, uint256 destinationChainId) external {
        // check receiver
        require(receiver != address(0), "INVALID_RECEIVER");
        // check data length
        require(data.length <= MAX_LENGTH, "EXCEEDS_MAX_LENGTH");
        // check destination chain id
        require(destinationChainId != 0, "INVALID_DESTINATION_CHAIN_ID");

        // State sync id will start with 1
        emit BridgeMsg(++counter, msg.sender, receiver, block.chainid, destinationChainId, data);
    }

    /**
     * @notice receives the batch of messages and executes them
     * @param batch batch of messages
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(
        BridgeMessage[] calldata batch,
        uint256[2] calldata signature,
        bytes calldata bitmap
    ) external {
        _verifyBatch(batch);

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    calculateMerkleRoot(batch),
                    batch[0].id,
                    batch[batch.length - 1].id,
                    batch[0].sourceChainId,
                    batch[0].destinationChainId
                )
            )
        );

        verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signature, bitmap);

        uint256 length = batch.length;
        for (uint256 i = 0; i < length; ) {
            _executeBridgeMessage(batch[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    function _verifyBatch(BridgeMessage[] calldata batch) private view {
        require(batch.length > 0, "EMPTY_BATCH");

        uint256 destinationChainId = block.chainid;
        uint256 sourceChainId = batch[0].sourceChainId;

        for (uint256 i = 0; i < batch.length; ) {
            BridgeMessage memory message = batch[i];
            require(message.sourceChainId == sourceChainId, "INVALID_SOURCE_CHAIN_ID");
            require(message.destinationChainId == destinationChainId, "INVALID_DESTINATION_CHAIN_ID");
            unchecked {
                ++i;
            }
        }
    }

    function _executeBridgeMessage(BridgeMessage calldata message) private {
        require(!processedEvents[message.id], "DestinationGateway: BRIDGE_MESSAGE_IS_ALREADY_PROCESSED");
        // Skip transaction if client has added flag, or receiver has no code
        if (message.receiver.code.length == 0) {
            emit BridgeMessageResult(message.id, false, message.sourceChainId, message.destinationChainId, "");
            return;
        }

        processedEvents[message.id] = true;

        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-no-eth
        (bool success, bytes memory returnData) = message.receiver.call(
            abi.encodeWithSignature(
                "onStateReceive(uint256,address,bytes)",
                message.id,
                message.sender,
                message.payload
            )
        );

        // if bridge message fails, revert flag
        if (!success) processedEvents[message.id] = false;

        // emit a ResultEvent indicating whether invocation of bridge message was successful or not
        // slither-disable-next-line reentrancy-events
        emit BridgeMessageResult(message.id, success, message.sourceChainId, message.destinationChainId, returnData);
    }

    // Function to calculate Merkle Root from an array of BridgeMessages
    function calculateMerkleRoot(BridgeMessage[] memory messages) internal pure returns (bytes32) {
        require(messages.length > 0, "No messages provided");

        // Convert the BridgeMessages to their keccak256 hashes (this will be the actual leaves)
        bytes32[] memory leaves = new bytes32[](messages.length);

        for (uint256 i = 0; i < messages.length; i++) {
            leaves[i] = keccak256(abi.encode(messages[i].id, messages[i].sourceChainId, messages[i].destinationChainId, messages[i].sender, messages[i].receiver, messages[i].payload));
        }

        // Pass the leaves to compute the Merkle root
        return Merkle.computeMerkleRoot(leaves);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
