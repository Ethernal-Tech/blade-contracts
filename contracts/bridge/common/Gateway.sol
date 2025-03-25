// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../internal/ValidatorSetStorage.sol";
import "../internal/BridgeStorage.sol";
import "../../interfaces/bridge/IGateway.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Gateway is ValidatorSetStorage, IGateway {
    uint256 public constant MAX_LENGTH = 2048;
    uint256 public counter;
    BridgeStorage public bridgeStorage;

    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => bool) public processedEvents;
    /// @custom:security write-protection="onlySystemCall()"
    mapping(uint256 => bool) public processedEventsRollback;

    event BridgeMessageResult(
        uint256 indexed id,
        bool indexed status,
        uint256 sourceChainID,
        uint256 destinationChainID,
        bool isRollback,
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
     * @notice initializes the contract
     * @param newBls address of the BLS library contract
     * @param newBn256G2 address of the BN256G2 library contract
     * @param validators list of validators
     * @param bsAddress address of the BridgeStorage contract (needed only for internal GW)
     */
    function initializeGW(
        IBLS newBls,
        IBN256G2 newBn256G2,
        Validator[] calldata validators,
        address bsAddress
    ) public initializer {
        _init(newBls, newBn256G2, validators);

        require(bsAddress != address(0), "INVALID_BRIDGE_STORAGE_ADDRESS");
        bridgeStorage = BridgeStorage(bsAddress);
    }

    /**
     *
     * @notice Generates sync state event based on receiver and data.
     * Anyone can call this method to emit an event. Receiver on Blade should add check based on sender.
     *
     * @param receiver Receiver address on Blade chain
     * @param data Data to send on Blade chain
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

        counter++;

        // State sync id will start with 1
        emit BridgeMsg(counter, msg.sender, receiver, block.chainid, destinationChainId, data);
    }

    /**
     * @notice receives the batch of messages and executes them
     * @param signedBatch batch with messages, signature and bitmap
     */
    // slither-disable-next-line protected-vars
    function receiveBatch(SignedBridgeMessageBatch calldata signedBatch) external virtual {
        if (address(bridgeStorage) != address(0)) {
            bridgeStorage.commitBatch(signedBatch);
        }

        _verifyBatch(signedBatch.batch.messages);

        bytes memory hash = abi.encode(
            keccak256(
                abi.encode(
                    signedBatch.batch.messages,
                    signedBatch.batch.sourceChainId,
                    signedBatch.batch.destinationChainId,
                    signedBatch.batch.threshold,
                    signedBatch.batch.numberOfRegularEvents,
                    signedBatch.batch.commitCounter
                )
            )
        );

        _verifySignature(bls.hashToPoint(DOMAIN_BRIDGE, hash), signedBatch.signature, signedBatch.bitmap);

        if (block.number > signedBatch.batch.threshold) {
            return;
        }

        uint256 length = signedBatch.batch.messages.length;
        for (uint256 i = 0; i < length; ) {
            if (!signedBatch.batch.messages[i].isRollback) {
                if (processedEvents[signedBatch.batch.messages[i].id]) continue;

                processedEvents[signedBatch.batch.messages[i].id] = true;

                _executeBridgeMessage(signedBatch.batch.messages[i]);
            } else {
                if (processedEventsRollback[signedBatch.batch.messages[i].id]) continue;

                processedEventsRollback[signedBatch.batch.messages[i].id] = true;

                _executeRollbackBridgeMessage(signedBatch.batch.messages[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function that verifies the batch
     * @param batch batch to verify
     */
    function _verifyBatch(BridgeMessage[] calldata batch) internal view {
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

    /**
     * @notice internal function that executes messages
     * @param message message to execute
     */
    function _executeBridgeMessage(BridgeMessage calldata message) internal {
        // revert transaction if client has added flag, or receiver has no code
        if (message.receiver.code.length == 0) {
            // slither-disable-next-line reentrancy-events
            emit BridgeMessageResult(
                message.id,
                false,
                message.sourceChainId,
                message.destinationChainId,
                message.isRollback,
                "receiver has no code"
            );

            return;
        }

        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-no-eth
        (bool success, bytes memory returnData) = message.receiver.call(
            abi.encodeWithSignature(
                "onStateReceive(uint256,address,bytes)",
                message.id,
                message.sender,
                message.payload
            )
        );

        // emit a ResultEvent indicating whether invocation of bridge message was successful
        // slither-disable-next-line reentrancy-events
        emit BridgeMessageResult(
            message.id,
            success,
            message.sourceChainId,
            message.destinationChainId,
            message.isRollback,
            returnData
        );
    }

    /**
     * @notice private function that executes rollback messages
     * @param message rollback message to execute
     */
    // slither-disable-start dead-code
    function _executeRollbackBridgeMessage(BridgeMessage calldata message) private {
        // slither-disable-next-line calls-loop,low-level-calls,reentrancy-no-eth
        (bool success, bytes memory returnData) = message.receiver.call(
            abi.encodeWithSignature(
                "onStateRollback(uint256,address,bytes)",
                message.id,
                message.sender,
                message.payload
            )
        );

        // emit a ResultEvent indicating whether invocation of bridge rollback message was successful or not
        // slither-disable-next-line reentrancy-events
        emit BridgeMessageResult(
            message.id,
            success,
            message.sourceChainId,
            message.destinationChainId,
            message.isRollback,
            returnData
        );
    }

    // slither-disable-end dead-code

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
