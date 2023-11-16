# StakeManager









## Methods

### WITHDRAWAL_WAIT_PERIOD

```solidity
function WITHDRAWAL_WAIT_PERIOD() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### domain

```solidity
function domain() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### getValidator

```solidity
function getValidator(address validator_) external view returns (struct Validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator_ | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | Validator | undefined |

### initialize

```solidity
function initialize(address newStakingToken, address newBls, address epochManager, string newDomain, GenesisValidator[] genesisValidators) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| newStakingToken | address | undefined |
| newBls | address | undefined |
| epochManager | address | undefined |
| newDomain | string | undefined |
| genesisValidators | GenesisValidator[] | undefined |

### pendingWithdrawals

```solidity
function pendingWithdrawals(address account) external view returns (uint256)
```

Calculates how much is yet to become withdrawable for account.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | The account to calculate amount for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Amount not yet withdrawable (in MATIC wei) |

### register

```solidity
function register(uint256[2] signature, uint256[4] pubkey) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| signature | uint256[2] | undefined |
| pubkey | uint256[4] | undefined |

### stake

```solidity
function stake(uint256 amount) external nonpayable
```

called by a validator to stake for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### stakeOf

```solidity
function stakeOf(address validator) external view returns (uint256 amount)
```

returns the amount staked by a validator for a child chain



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### totalStake

```solidity
function totalStake() external view returns (uint256 amount)
```

returns the total amount staked for all child chains




#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### unstake

```solidity
function unstake(uint256 amount) external nonpayable
```

called by a validator to unstake



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### validators

```solidity
function validators(address) external view returns (uint256 stake, bool isWhitelisted, bool isActive)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| stake | uint256 | undefined |
| isWhitelisted | bool | undefined |
| isActive | bool | undefined |

### whitelistValidators

```solidity
function whitelistValidators(address[] validators_) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validators_ | address[] | undefined |

### withdraw

```solidity
function withdraw() external nonpayable
```

allows a validator to complete a withdrawal

*calls the bridge to release the funds on root*


### withdrawStake

```solidity
function withdrawStake(address to, uint256 amount) external nonpayable
```

allows a validator to withdraw released stake



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | undefined |
| amount | uint256 | undefined |

### withdrawable

```solidity
function withdrawable(address account) external view returns (uint256 amount)
```

Calculates how much can be withdrawn for account in this epoch.



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | The account to calculate amount for |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | Amount withdrawable (in MATIC wei) |

### withdrawableStake

```solidity
function withdrawableStake(address validator) external view returns (uint256 amount)
```

returns the amount of stake a validator can withdraw



#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |



## Events

### AddedToWhitelist

```solidity
event AddedToWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### ChildManagerRegistered

```solidity
event ChildManagerRegistered(uint256 indexed id, address indexed manager)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| manager `indexed` | address | undefined |

### Initialized

```solidity
event Initialized(uint8 version)
```



*Triggered when the contract has been initialized or reinitialized.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| version  | uint8 | undefined |

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### StakeAdded

```solidity
event StakeAdded(address indexed validator, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| amount  | uint256 | undefined |

### StakeRemoved

```solidity
event StakeRemoved(address indexed validator, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| amount  | uint256 | undefined |

### StakeWithdrawn

```solidity
event StakeWithdrawn(address indexed validator, address indexed recipient, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| recipient `indexed` | address | undefined |
| amount  | uint256 | undefined |

### ValidatorDeactivated

```solidity
event ValidatorDeactivated(address indexed validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |

### ValidatorRegistered

```solidity
event ValidatorRegistered(address indexed validator, uint256[4] blsKey)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator `indexed` | address | undefined |
| blsKey  | uint256[4] | undefined |

### Withdrawal

```solidity
event Withdrawal(address indexed account, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| amount  | uint256 | undefined |



## Errors

### InvalidSignature

```solidity
error InvalidSignature(address validator)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| validator | address | undefined |

### Unauthorized

```solidity
error Unauthorized(string message)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| message | string | undefined |


