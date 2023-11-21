# IEpochManager



> IEpochManager

Distributes rewards to validators for committed epochs



## Methods

### balanceOfAt

```solidity
function balanceOfAt(address account, uint256 epochNumber) external view returns (uint256)
```

returns a validator balance for a given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### commitEpoch

```solidity
function commitEpoch(uint256 id, Epoch epoch) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id | uint256 | undefined |
| epoch | Epoch | undefined |

### distributeRewardFor

```solidity
function distributeRewardFor(uint256 epochId, Uptime[] uptime) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |
| uptime | Uptime[] | undefined |

### getCurrentEpochId

```solidity
function getCurrentEpochId() external view returns (uint256)
```

return currentEpochId




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### paidRewardPerEpoch

```solidity
function paidRewardPerEpoch(uint256 epochId) external view returns (uint256)
```

returns the total reward paid for the given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### pendingRewards

```solidity
function pendingRewards(address account) external view returns (uint256)
```

returns the pending reward for the given account



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### totalSupplyAt

```solidity
function totalSupplyAt(uint256 epochNumber) external view returns (uint256)
```

returns the total supply for a given epoch



#### Parameters

| Name | Type | Description |
|---|---|---|
| epochNumber | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdrawReward

```solidity
function withdrawReward() external nonpayable
```

withdraws pending rewards for the sender (validator)






## Events

### NewEpoch

```solidity
event NewEpoch(uint256 indexed id, uint256 indexed startBlock, uint256 indexed endBlock, bytes32 epochRoot)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| id `indexed` | uint256 | undefined |
| startBlock `indexed` | uint256 | undefined |
| endBlock `indexed` | uint256 | undefined |
| epochRoot  | bytes32 | undefined |

### RewardDistributed

```solidity
event RewardDistributed(uint256 indexed epochId, uint256 totalReward)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| epochId `indexed` | uint256 | undefined |
| totalReward  | uint256 | undefined |



