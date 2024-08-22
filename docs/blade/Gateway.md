# Gateway









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

### MAX_LENGTH

```solidity
function MAX_LENGTH() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### VALIDATOR_PKCHECK_PRECOMPILE

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### VALIDATOR_PKCHECK_PRECOMPILE_GAS

```solidity
function VALIDATOR_PKCHECK_PRECOMPILE_GAS() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### commitValidatorSet

```solidity
function commitValidatorSet(Validator[] newValidatorSet, uint256[2] signature, bytes bitmap) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newValidatorSet | Validator[] | undefined |
| signature | uint256[2] | undefined |
| bitmap | bytes | undefined |

### counter

```solidity
function counter() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

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

### processedEvents

```solidity
function processedEvents(uint256) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### receiveBatch

```solidity
function receiveBatch(BridgeMessageBatch batch, uint256[2] signature, bytes bitmap) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| batch | BridgeMessageBatch | undefined |
| signature | uint256[2] | undefined |
| bitmap | bytes | undefined |

### sendBridgeMsg

```solidity
function sendBridgeMsg(address receiver, bytes data, uint256 destinationChainId) external nonpayable
```

Generates sync state event based on receiver and data. Anyone can call this method to emit an event. Receiver on Polygon should add check based on sender.



#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | Receiver address on Polygon chain |
| data | bytes | Data to send on Polygon chain |
| destinationChainId | uint256 | Chain id of destination chain |

### totalVotingPower

```solidity
function totalVotingPower() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |



## Events

### BridgeMessageEvent

```solidity
event BridgeMessageEvent(uint256 indexed id, address indexed sender, address indexed receiver, bytes data, uint256 sourceChainId, uint256 destinationChainId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| sender `indexed` | address | undefined |
| receiver `indexed` | address | undefined |
| data  | bytes | undefined |
| sourceChainId  | uint256 | undefined |
| destinationChainId  | uint256 | undefined |

### BridgeMessageResult

```solidity
event BridgeMessageResult(uint256 indexed counter, bool indexed status, bytes message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| counter `indexed` | uint256 | undefined |
| status `indexed` | bool | undefined |
| message  | bytes | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### NewValidatorSet

```solidity
event NewValidatorSet(Validator[] newValidatorSet)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newValidatorSet  | Validator[] | undefined |



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


