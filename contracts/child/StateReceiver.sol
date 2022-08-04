// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {System} from "./System.sol";
import {Merkle} from "../common/Merkle.sol";

// StateReceiver is the contract which executes and relays the state data on Polygon
contract StateReceiver is System {
    using Merkle for bytes32;

    struct StateSync {
        uint256 id;
        address sender;
        address receiver;
        bytes data;
        bool skip;
    }

    struct StateSyncBundle {
        uint256 startId;
        uint256 endId;
        uint256 leaves;
        bytes32 root;
    }
    // Maximum gas provided for each message call
    // slither-disable-next-line too-many-digits
    uint256 public constant MAX_GAS = 300000;
    // Index of the next event which needs to be processed
    /// @custom:security write-protection="onlySystemCall()"
    uint256 public counter;
    uint256 public bundleCounter;
    uint256 public lastExecutedBundleCounter;
    uint256 public currentLeafIndex;

    mapping(uint256 => StateSyncBundle) public bundles;

    // 0=success, 1=failure, 2=skip
    enum ResultStatus {
        SUCCESS,
        FAILURE,
        SKIP
    }

    event StateSyncResult(
        uint256 indexed counter,
        ResultStatus indexed status,
        bytes32 message
    );

    function commit(StateSyncBundle calldata bundle, bytes calldata signature) external onlySystemCall {
        // create sig data for verification
        // counter, sender, receiver, data and result (skip) should be
        // part of the dataHash. Otherwise data can be manipulated for same sigs
        //
        // dataHash = hash(counter, sender, receiver, data, result)
        bytes32 dataHash = keccak256(abi.encode(bundle));

        _checkPubkeyAggregation(dataHash, signature);

        bundles[bundleCounter++] = bundle;
    }

    function execute(bytes32[] calldata proof, StateSync[] calldata objs)
        external
    {
        require(
            lastExecutedBundleCounter < bundleCounter,
            "NOTHING_TO_EXECUTE"
        );

        bytes32 dataHash = keccak256(abi.encode(objs));

        StateSyncBundle memory bundle = bundles[lastExecutedBundleCounter];

        uint256 leafIndex = currentLeafIndex;

        require(dataHash.checkMembership(leafIndex++, bundle.root, proof), "INVALID_PROOF");

        if (leafIndex == bundle.leaves) {
            currentLeafIndex = 0;
            delete bundles[lastExecutedBundleCounter++];
        } else {
            currentLeafIndex++;
        }

        uint256 currentId = counter;
        // execute state sync
        for (uint256 i = 0; i < objs.length; ++i) {
            _executeStateSync(currentId++, objs[i]);
        }

        counter = currentId;
    }

    //
    // Execute state sync
    //

    function _executeStateSync(uint256 prevId, StateSync calldata obj)
        internal
    {
        require(prevId + 1 == obj.id, "ID_NOT_SEQUENTIAL");

        // Skip transaction if client has added flag, or receiver has no code
        if (obj.skip || obj.receiver.code.length == 0) {
            emit StateSyncResult(obj.id, ResultStatus.SKIP, "");
            return;
        }

        // Execute `onStateReceive` method on target using max gas limit
        bytes memory paramData = abi.encodeWithSignature(
            "onStateReceive(uint256,address,bytes)",
            obj.id,
            obj.sender,
            obj.data
        );

        // slither-disable-next-line calls-loop,low-level-calls
        (bool success, bytes memory returnData) = obj.receiver.call{ // solhint-disable-line avoid-low-level-calls
            gas: MAX_GAS
        }(paramData);

        bytes32 message = bytes32(returnData);

        // emit a ResultEvent indicating whether invocation of bridge was successful or not
        if (success) {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.SUCCESS, message);
        } else {
            // slither-disable-next-line reentrancy-events
            emit StateSyncResult(obj.id, ResultStatus.FAILURE, message);
        }
    }

    function _checkPubkeyAggregation(bytes32 message, bytes calldata signature)
        internal
        view
    {
        // verify signatures` for provided sig data and sigs bytes
        // solhint-disable-next-line avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (
            bool callSuccess,
            bytes memory returnData
        ) = VALIDATOR_PKCHECK_PRECOMPILE.staticcall{
                gas: VALIDATOR_PKCHECK_PRECOMPILE_GAS
            }(abi.encode(message, signature));
        bool verified = abi.decode(returnData, (bool));
        require(callSuccess && verified, "SIGNATURE_VERIFICATION_FAILED");
    }
}
