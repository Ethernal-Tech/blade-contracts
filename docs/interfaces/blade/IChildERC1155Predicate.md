# IChildERC1155Predicate









## Methods

### initialize

```solidity
function initialize(address newGateway, address newStateReceiver, address newRootERC721Predicate, address newChildTokenTemplate) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | undefined |
| newStateReceiver | address | undefined |
| newRootERC721Predicate | address | undefined |
| newChildTokenTemplate | address | undefined |

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
function withdraw(contract IChildERC1155 childToken, uint256 tokenId, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC1155 | undefined |
| tokenId | uint256 | undefined |
| amount | uint256 | undefined |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC1155 childToken, address receiver, uint256 tokenId, uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC1155 | undefined |
| receiver | address | undefined |
| tokenId | uint256 | undefined |
| amount | uint256 | undefined |




