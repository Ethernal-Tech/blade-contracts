
pragma solidity ^0.8.12;

mapping(uint256 => BridgeMessageBatch) public batches;
/// @custom:security write-protection="onlySystemCall()"
uint256 public batchCounter;

event NewBatch(uint256 Id);

/**
 * @param id id of message
 * @param sourceChainId id of source chain
 * @param destinationChainId id of destination chain
 * @param sender sender account of this bridge message
 * @param receiver receiver account of this bridge message
 * @param payload payload 
 */

struct BridgeMessage{
    uint256 id;
    uint256 sourceChainId;
    uint256 destinationChainId;
    address indexed sender;
    address indexed receiver;
    bytes payload;
}

/**
 * @param messages list of all messages in batch
 * @param signature validators signature 
 * @param bitmap 
 */

struct BridgeMessageBatch{
    []BridgeMessage messages;
    uint256[2] signature;
    bytes bitmap;
}

/**
 * @notice commits new batch
 * @param batch new batch
 */
function commitBatch(batch BridgeMessageBatch) onlySystemCall{
    require(batch.sourceChainId != batch.destinationChainId, "EQAUL_CHAIN_IDs");
    require(batch.sender != batch.receiver, "EQUAL_SENDER_RECEIVER_ADDRESS")

    batches[batchCounter++] = batch;

    emit NewBatch(batchCounter-1);
}

