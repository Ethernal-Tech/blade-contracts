# IChildERC20Predicate









## Methods

### initialize

```solidity
function initialize(address newGateway, address newRootERC20Predicate, address newDestinationTokenTemplate, address newNativeTokenRootAddress, uint256 newDestinationChainId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | undefined |
| newRootERC20Predicate | address | undefined |
| newDestinationTokenTemplate | address | undefined |
| newNativeTokenRootAddress | address | undefined |
| newDestinationChainId | uint256 | undefined |

### onStateReceive

```solidity
function onStateReceive(uint256 id, address sender, bytes data) external nonpayable
```

Called by gateway when state is received from source chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| sender | address | Address of the sender on the child chain |
| data | bytes | Data sent by the sender |

### onStateRollback

```solidity
function onStateRollback(uint256 id, address sender, bytes data) external nonpayable
```

Called by gateway when state is received from source chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| sender | address | Address of the sender on the root chain |
| data | bytes | Data sent by the sender |

### withdraw

```solidity
function withdraw(contract IChildERC20 childToken, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | undefined |
| amount | uint256 | undefined |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC20 childToken, address receiver, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC20 | undefined |
| receiver | address | undefined |
| amount | uint256 | undefined |




