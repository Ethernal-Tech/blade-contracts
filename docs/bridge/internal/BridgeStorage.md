# BridgeStorage









## Methods

### ALLOWLIST_PRECOMPILE

```solidity
function ALLOWLIST_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### BLOCKLIST_PRECOMPILE

```solidity
function BLOCKLIST_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TOKEN_CONTRACT

```solidity
function NATIVE_TOKEN_CONTRACT() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TRANSFER_PRECOMPILE

```solidity
function NATIVE_TRANSFER_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### NATIVE_TRANSFER_PRECOMPILE_GAS

```solidity
function NATIVE_TRANSFER_PRECOMPILE_GAS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### READ_ADDRESSLIST_GAS

```solidity
function READ_ADDRESSLIST_GAS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### SYSTEM

```solidity
function SYSTEM() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### addresses

```solidity
function addresses(uint256) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### batchCommitCounter

```solidity
function batchCommitCounter(bytes) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### batchCounter

```solidity
function batchCounter() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### batches

```solidity
function batches(uint256) external view returns (struct BridgeMessageBatch batch, bytes bitmap, uint256 validatorSetBatchId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| batch | BridgeMessageBatch | undefined |
| bitmap | bytes | undefined |
| validatorSetBatchId | uint256 | undefined |

### bls

```solidity
function bls() external view returns (contract IBLS)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IBLS | undefined |

### bn256G2

```solidity
function bn256G2() external view returns (contract IBN256G2)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IBN256G2 | undefined |

### commitBatch

```solidity
function commitBatch(SignedBridgeMessageBatch signedBatch) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signedBatch | SignedBridgeMessageBatch | undefined |

### commitValidatorSet

```solidity
function commitValidatorSet(Validator[] newValidatorSet, uint256[2] signature, bytes bitmap, BlockMetadata blockMetadata) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newValidatorSet | Validator[] | undefined |
| signature | uint256[2] | undefined |
| bitmap | bytes | undefined |
| blockMetadata | BlockMetadata | undefined |

### commitedValidatorSets

```solidity
function commitedValidatorSets(uint256) external view returns (bytes bitmap, struct BlockMetadata blockMetadata)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| bitmap | bytes | undefined |
| blockMetadata | BlockMetadata | undefined |

### currentValidatorSet

```solidity
function currentValidatorSet(uint256) external view returns (address _address, uint256 votingPower)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _address | address | undefined |
| votingPower | uint256 | undefined |

### currentValidatorSetHash

```solidity
function currentValidatorSetHash() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### currentValidatorSetLength

```solidity
function currentValidatorSetLength() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getCommittedBatch

```solidity
function getCommittedBatch(uint256 id) external view returns (struct SignedBridgeMessageBatch)
```

Returns the committed batch based on provided id



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | batch id |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | SignedBridgeMessageBatch | undefined |

### getCommittedBatches

```solidity
function getCommittedBatches(uint256 firstBatchNumber) external view returns (struct SignedBridgeMessageBatch[])
```

Returns all committed batches from the provided ID to the end of the array



#### Parameters

| Name | Type | Description |
|---|---|---|
| firstBatchNumber | uint256 | batch id |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | SignedBridgeMessageBatch[] | undefined |

### getCommittedValidatorSet

```solidity
function getCommittedValidatorSet(uint256 id) external view returns (struct SignedValidatorSet)
```

Returns the committed validator set based on provided id



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | validator set id |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | SignedValidatorSet | undefined |

### getConfirmedRollbackedE2I

```solidity
function getConfirmedRollbackedE2I(uint256 chainId, uint256 id) external view returns (bool)
```

Returns true if message with id is rollbacked on E2I transfer, else false



#### Parameters

| Name | Type | Description |
|---|---|---|
| chainId | uint256 | external chain id |
| id | uint256 | message id |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### getConfirmedRollbackedI2E

```solidity
function getConfirmedRollbackedI2E(uint256 chainId, uint256 id) external view returns (bool)
```

Returns true if message with id is rollbacked on I2E transfer, else false



#### Parameters

| Name | Type | Description |
|---|---|---|
| chainId | uint256 | external chain id |
| id | uint256 | message id |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### initialize

```solidity
function initialize(contract IBLS newBls, contract IBN256G2 newBn256G2, Validator[] validators) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newBls | contract IBLS | undefined |
| newBn256G2 | contract IBN256G2 | undefined |
| validators | Validator[] | undefined |

### initializeBS

```solidity
function initializeBS(contract IBLS newBls, contract IBN256G2 newBn256G2, Validator[] validators, address[] addressesGateway) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newBls | contract IBLS | undefined |
| newBn256G2 | contract IBN256G2 | undefined |
| validators | Validator[] | undefined |
| addressesGateway | address[] | undefined |

### lastCommittedE2I

```solidity
function lastCommittedE2I(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### lastCommittedI2E

```solidity
function lastCommittedI2E(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### rollbackedE2I

```solidity
function rollbackedE2I(uint256, uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### rollbackedI2E

```solidity
function rollbackedI2E(uint256, uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalVotingPower

```solidity
function totalVotingPower() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### validatorSetCounter

```solidity
function validatorSetCounter() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### NewBatch

```solidity
event NewBatch(uint256 indexed id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |

### NewValidatorSet

```solidity
event NewValidatorSet(Validator[] newValidatorSet)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newValidatorSet  | Validator[] | undefined |

### NewValidatorSetStored

```solidity
event NewValidatorSetStored(uint256 indexed id)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


