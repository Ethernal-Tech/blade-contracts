# AAStakeManager





manage deposits and stakes. deposit is just a balance used to pay for UserOperations (either by a paymaster or an account) stake is value locked for at least &quot;unstakeDelay&quot; by a paymaster.



## Methods

### addStake

```solidity
function addStake(uint32 unstakeDelaySec) external payable
```

add to the account&#39;s stake - amount and delay any pending unstake is first cancelled.



#### Parameters

| Name | Type | Description |
|---|---|---|
| unstakeDelaySec | uint32 | the new lock duration before the deposit can be withdrawn. |

### balanceOf

```solidity
function balanceOf(address account) external view returns (uint256)
```

return the deposit (for gas payment) of the account



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### depositTo

```solidity
function depositTo(address account) external payable
```

add to the deposit of the given account



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

### deposits

```solidity
function deposits(address) external view returns (uint112 deposit, bool staked, uint112 stake, uint32 unstakeDelaySec, uint48 withdrawTime)
```

maps paymaster to their deposits and stakes



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| deposit | uint112 | undefined |
| staked | bool | undefined |
| stake | uint112 | undefined |
| unstakeDelaySec | uint32 | undefined |
| withdrawTime | uint48 | undefined |

### getDepositInfo

```solidity
function getDepositInfo(address account) external view returns (struct IAAStakeManager.DepositInfo info)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| info | IAAStakeManager.DepositInfo | - full deposit information of given account |

### unlockStake

```solidity
function unlockStake() external nonpayable
```

attempt to unlock the stake. the value can be withdrawn (using withdrawStake) after the unstake delay.




### withdrawStake

```solidity
function withdrawStake(address payable withdrawAddress) external nonpayable
```

withdraw from the (unlocked) stake. must first call unlockStake and wait for the unstakeDelay to pass



#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | the address to send withdrawn value. |

### withdrawTo

```solidity
function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external nonpayable
```

withdraw from the deposit.



#### Parameters

| Name | Type | Description |
|---|---|---|
| withdrawAddress | address payable | the address to send withdrawn value. |
| withdrawAmount | uint256 | the amount to withdraw. |



## Events

### Deposited

```solidity
event Deposited(address indexed account, uint256 totalDeposit)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| totalDeposit  | uint256 | undefined |

### StakeLocked

```solidity
event StakeLocked(address indexed account, uint256 totalStaked, uint256 unstakeDelaySec)
```

Emitted when stake or unstake delay are modified



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| totalStaked  | uint256 | undefined |
| unstakeDelaySec  | uint256 | undefined |

### StakeUnlocked

```solidity
event StakeUnlocked(address indexed account, uint256 withdrawTime)
```

Emitted once a stake is scheduled for withdrawal



#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| withdrawTime  | uint256 | undefined |

### StakeWithdrawn

```solidity
event StakeWithdrawn(address indexed account, address withdrawAddress, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| withdrawAddress  | address | undefined |
| amount  | uint256 | undefined |

### Withdrawn

```solidity
event Withdrawn(address indexed account, address withdrawAddress, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| account `indexed` | address | undefined |
| withdrawAddress  | address | undefined |
| amount  | uint256 | undefined |



