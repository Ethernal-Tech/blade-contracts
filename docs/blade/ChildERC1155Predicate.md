# ChildERC1155Predicate

*Polygon Technology (@QEDK, @wschwab)*

> ChildERC1155Predicate

Enables ERC1155 token deposits and withdrawals across an arbitrary root chain and child chain



## Methods

### DEPOSIT_BATCH_SIG

```solidity
function DEPOSIT_BATCH_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### DEPOSIT_SIG

```solidity
function DEPOSIT_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### MAP_TOKEN_SIG

```solidity
function MAP_TOKEN_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### WITHDRAW_BATCH_SIG

```solidity
function WITHDRAW_BATCH_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### WITHDRAW_SIG

```solidity
function WITHDRAW_SIG() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### destinationChainId

```solidity
function destinationChainId() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### destinationTokenTemplate

```solidity
function destinationTokenTemplate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### gateway

```solidity
function gateway() external view returns (contract IGateway)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IGateway | undefined |

### initialize

```solidity
function initialize(address newGateway, address newRootERC1155Predicate, address newDestinationTokenTemplate, uint256 newDestinationChainId) external nonpayable
```

Initialization function for ChildERC1155Predicate

*Can only be called once.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | Address of gateway contract |
| newRootERC1155Predicate | address | Address of root ERC1155 predicate to communicate with |
| newDestinationTokenTemplate | address | Address of destination token implementation to deploy clones of |
| newDestinationChainId | uint256 | Chain ID of destination chain |

### onStateReceive

```solidity
function onStateReceive(uint256, address sender, bytes data) external nonpayable
```

Function to be used for token deposits

*Can be extended to include other signatures for more functionality*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | Address of the sender on the root chain |
| data | bytes | Data sent by the sender |

### rootERC1155Predicate

```solidity
function rootERC1155Predicate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### rootTokenToChildToken

```solidity
function rootTokenToChildToken(address) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### withdraw

```solidity
function withdraw(contract IChildERC1155 childToken, uint256 tokenId, uint256 amount) external nonpayable
```

Function to withdraw tokens from the withdrawer to themselves on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC1155 | Address of the child token being withdrawn |
| tokenId | uint256 | Index of the NFT to withdraw |
| amount | uint256 | Amount of the NFT to withdraw |

### withdrawBatch

```solidity
function withdrawBatch(contract IChildERC1155 childToken, address[] receivers, uint256[] tokenIds, uint256[] amounts) external nonpayable
```

Function to batch withdraw tokens from the withdrawer to other addresses on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC1155 | Address of the child token being withdrawn |
| receivers | address[] | Addresses of the receivers on the root chain |
| tokenIds | uint256[] | indices of the NFTs to withdraw |
| amounts | uint256[] | Amounts of NFTs to withdraw |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC1155 childToken, address receiver, uint256 tokenId, uint256 amount) external nonpayable
```

Function to withdraw tokens from the withdrawer to another address on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC1155 | Address of the child token being withdrawn |
| receiver | address | Address of the receiver on the root chain |
| tokenId | uint256 | Index of the NFT to withdraw |
| amount | uint256 | Amount of NFT to withdraw |



## Events

### ERC1155Deposit

```solidity
event ERC1155Deposit(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### ERC1155DepositBatch

```solidity
event ERC1155DepositBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### ERC1155Withdraw

```solidity
event ERC1155Withdraw(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### ERC1155WithdrawBatch

```solidity
event ERC1155WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### TokenMapped

```solidity
event TokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



