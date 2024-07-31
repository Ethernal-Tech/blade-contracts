# ChildERC721Predicate

*Polygon Technology (@QEDK, @wschwab)*

> ChildERC721Predicate

Enables ERC721 token deposits and withdrawals across an arbitrary root chain and child chain



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
function initialize(address newGateway, address newRootERC721Predicate, address newSourceTokenTemplate) external nonpayable
```

Initialization function for ChildERC721Predicate

*Can only be called once. `newNativeTokenRootAddress` should be set to zero where root token does not exist.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | Address of gateway contract |
| newRootERC721Predicate | address | Address of root ERC721 predicate to communicate with |
| newSourceTokenTemplate | address | Address of source token implementation to deploy clones of |

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

### rootERC721Predicate

```solidity
function rootERC721Predicate() external view returns (address)
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

### sourceTokenTemplate

```solidity
function sourceTokenTemplate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### withdraw

```solidity
function withdraw(contract IChildERC721 childToken, uint256 tokenId) external nonpayable
```

Function to withdraw tokens from the withdrawer to themselves on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | Address of the child token being withdrawn |
| tokenId | uint256 | index of the NFT to withdraw |

### withdrawBatch

```solidity
function withdrawBatch(contract IChildERC721 childToken, address[] receivers, uint256[] tokenIds) external nonpayable
```

Function to batch withdraw tokens from the withdrawer to other addresses on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | Address of the child token being withdrawn |
| receivers | address[] | Addresses of the receivers on the root chain |
| tokenIds | uint256[] | indices of the NFTs to withdraw |

### withdrawTo

```solidity
function withdrawTo(contract IChildERC721 childToken, address receiver, uint256 tokenId) external nonpayable
```

Function to withdraw tokens from the withdrawer to another address on the root chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| childToken | contract IChildERC721 | Address of the child token being withdrawn |
| receiver | address | Address of the receiver on the root chain |
| tokenId | uint256 | index of the NFT to withdraw |



## Events

### ERC721Deposit

```solidity
event ERC721Deposit(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### ERC721DepositBatch

```solidity
event ERC721DepositBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

### ERC721Withdraw

```solidity
event ERC721Withdraw(address indexed rootToken, address indexed childToken, address sender, address indexed receiver, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |

### ERC721WithdrawBatch

```solidity
event ERC721WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed sender, address[] receivers, uint256[] tokenIds)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| sender `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |

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



