# RootMintableERC1155PredicateAccessList

*Polygon Technology (@QEDK)*

> RootMintableERC1155PredicateAccessList

Enables child-chain origin ERC1155 token deposits and withdrawals (only from allowlisted address, and not from blocklisted addresses) across an arbitrary root chain and child chain



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

### acceptOwnership

```solidity
function acceptOwnership() external nonpayable
```



*The new owner accepts the ownership transfer.*


### childERC1155Predicate

```solidity
function childERC1155Predicate() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### deposit

```solidity
function deposit(contract IERC1155MetadataURI rootToken, uint256 tokenId, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to themselves on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| tokenId | uint256 | Index of the NFT to deposit |
| amount | uint256 | Amount to deposit |

### depositBatch

```solidity
function depositBatch(contract IERC1155MetadataURI rootToken, address[] receivers, uint256[] tokenIds, uint256[] amounts) external nonpayable
```

Function to deposit tokens from the depositor to other addresses on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| receivers | address[] | Addresses of the receivers on the child chain |
| tokenIds | uint256[] | Indeices of the NFTs to deposit |
| amounts | uint256[] | Amounts to deposit |

### depositTo

```solidity
function depositTo(contract IERC1155MetadataURI rootToken, address receiver, uint256 tokenId, uint256 amount) external nonpayable
```

Function to deposit tokens from the depositor to another address on the child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token being deposited |
| receiver | address | undefined |
| tokenId | uint256 | Index of the NFT to deposit |
| amount | uint256 | Amount to deposit |

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
function initialize(address newGateway, address newChildERC1155Predicate, address newDestinationTokenTemplate) external nonpayable
```

Initialization function for RootERC1155Predicate

*Can only be called once.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | Address of gateway to send deposit information to |
| newChildERC1155Predicate | address | Address of child ERC1155 predicate to communicate with |
| newDestinationTokenTemplate | address | Address of child token template to deploy clones of |

### initialize

```solidity
function initialize(address newGateway, address newChildERC1155Predicate, address newTokenTemplate, bool newUseAllowList, bool newUseBlockList, address newOwner) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newGateway | address | undefined |
| newChildERC1155Predicate | address | undefined |
| newTokenTemplate | address | undefined |
| newUseAllowList | bool | undefined |
| newUseBlockList | bool | undefined |
| newOwner | address | undefined |

### mapToken

```solidity
function mapToken(contract IERC1155MetadataURI rootToken) external nonpayable returns (address childToken)
```

Function to be used for token mapping

*Called internally on deposit if token is not mapped already*

#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken | contract IERC1155MetadataURI | Address of the root token to map |

#### Returns

| Name | Type | Description |
|---|---|---|
| childToken | address | Address of the mapped child token |

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256[] | undefined |
| _3 | uint256[] | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) external nonpayable returns (bytes4)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | uint256 | undefined |
| _4 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### onStateReceive

```solidity
function onStateReceive(uint256, address sender, bytes data) external nonpayable
```

Function to be used for token withdrawals

*Can be extended to include other signatures for more functionality*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| sender | address | Address of the sender on the child chain |
| data | bytes | Data sent by the sender |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### pendingOwner

```solidity
function pendingOwner() external view returns (address)
```



*Returns the address of the pending owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby disabling any functionality that is only available to the owner.*


### setAllowList

```solidity
function setAllowList(bool newUseAllowList) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newUseAllowList | bool | undefined |

### setBlockList

```solidity
function setBlockList(bool newUseBlockList) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newUseBlockList | bool | undefined |

### sourceTokenToDestinationToken

```solidity
function sourceTokenToDestinationToken(address) external view returns (address)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one. Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

### AllowListUsageSet

```solidity
event AllowListUsageSet(uint256 indexed block, bool indexed status)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| block `indexed` | uint256 | undefined |
| status `indexed` | bool | undefined |

### BlockListUsageSet

```solidity
event BlockListUsageSet(uint256 indexed block, bool indexed status)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| block `indexed` | uint256 | undefined |
| status `indexed` | bool | undefined |

### ERC1155Deposit

```solidity
event ERC1155Deposit(address indexed rootToken, address indexed childToken, address depositor, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### ERC1155DepositBatch

```solidity
event ERC1155DepositBatch(address indexed rootToken, address indexed childToken, address indexed depositor, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| depositor `indexed` | address | undefined |
| receivers  | address[] | undefined |
| tokenIds  | uint256[] | undefined |
| amounts  | uint256[] | undefined |

### ERC1155Withdraw

```solidity
event ERC1155Withdraw(address indexed rootToken, address indexed childToken, address withdrawer, address indexed receiver, uint256 tokenId, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer  | address | undefined |
| receiver `indexed` | address | undefined |
| tokenId  | uint256 | undefined |
| amount  | uint256 | undefined |

### ERC1155WithdrawBatch

```solidity
event ERC1155WithdrawBatch(address indexed rootToken, address indexed childToken, address indexed withdrawer, address[] receivers, uint256[] tokenIds, uint256[] amounts)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |
| withdrawer `indexed` | address | undefined |
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

### OwnershipTransferStarted

```solidity
event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### TokenMapped

```solidity
event TokenMapped(address indexed rootToken, address indexed childToken)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rootToken `indexed` | address | undefined |
| childToken `indexed` | address | undefined |



## Errors

### Unauthorized

```solidity
error Unauthorized(string only)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| only | string | undefined |


