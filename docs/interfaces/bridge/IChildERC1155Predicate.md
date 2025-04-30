# IChildERC1155Predicate









## Methods

### initialize

```solidity
function initialize(address newGateway, address newRootERC721Predicate, address newDestinationTokenTemplate, uint256 newDestinationChainId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | undefined |
| newRootERC721Predicate | address | undefined |
| newDestinationTokenTemplate | address | undefined |
| newDestinationChainId | uint256 | undefined |

### onMsgReceive

```solidity
function onMsgReceive(uint256 id, address sender, bytes data) external nonpayable
```

Called by gateway when state is received from source chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| sender | address | Address of the sender on the child chain |
| data | bytes | Data sent by the sender |

### onMsgRollback

```solidity
function onMsgRollback(uint256 id, address sender, bytes data) external nonpayable
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




