# IChildERC20Predicate









## Methods

### initialize

```solidity
function initialize(address newGateway, address newRootERC20Predicate, address newDestinationTokenTemplate, address newNativeTokenRootAddress) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | undefined |
| newRootERC20Predicate | address | undefined |
| newDestinationTokenTemplate | address | undefined |
| newNativeTokenRootAddress | address | undefined |

### onStateReceive

```solidity
function onStateReceive(uint256 counter, address sender, bytes data) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| counter | uint256 | undefined |
| sender | address | undefined |
| data | bytes | undefined |

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




