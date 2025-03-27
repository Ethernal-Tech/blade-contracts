# Bridge

## Bridge contracts provide bridge functionality

### Internal

This directory contains contracts meant for usage on blade chain.

#### BridgeStorage

The BridgeStorage contract is a fundamental component of a multi-chain bridge protocol, primarily focused on storing and managing signed bridge message batches that enable secure cross-chain communication. It extends ValidatorSetStorage, which is essential for verifying signatures on committed batches, ensuring the integrity and reliability of both message batches and validator set updates.

#### ValidatorSetStorage

The ValidatorSetStorage contract is responsible for storing and updating validator sets used for validating cross-chain transactions. It verifies validator signatures using BLS (Boneh-Lynn-Shacham) cryptography, ensuring that changes to the validator set meet the required quorum before being committed.

#### NativeERC20

The NativeERC20 contract represents the native token on Blade. It facilitates native token interactions while maintaining compatibility with ERC20-like functions.

#### NativeERC20Mintable

NativeERC20Mintable is an ERC20-compatible contract that represents the native token on Blade chains. It enables seamless interaction with the native token while maintaining compatibility with ERC20-like functions. The contract allows for minting and burning of tokens.

### Common

This directory contains contracts meant for usage on both Internal(blade) and external chains.

#### Gateway

The Gateway contract is a core component of a blockchain bridge system, responsible for handling message passing between different blockchain networks. In some cases it interacts with the BridgeStorage contract and facilitates state synchronization through events.

#### BladeManager

The BladeManager contract is a critical component of the blockchain bridge system, responsible for managing the genesis state and token balances during the initial phase of a new blockchain network. It facilitates the allocation of premined and staked tokens, ensures validator participation, and interacts with the RootERC20Predicate contract to lock native tokens on the root chain. Additionally, it enforces access control mechanisms and prevents unauthorized actions during the genesis phase.

#### TestRollbackGateway

The TestRollbackGateway contract extends the Gateway contract and is designed to simulate and test the handling of rollback operations in the blockchain bridge system. It overrides the receiveBatch function to process a batch of messages. For each message, the contract either executes the bridge message or simulates a rollback if the message ID is even, emitting the corresponding result.

#### Child(ERC20/721/1155)Predicates

The ChildERCPredicate contracts enables the deposit and withdrawal of tokens between a root chain and a child chain in a blockchain bridge system. It uses Clones to create destination tokens, and the contract listens for state changes like deposits and withdrawals, handling them accordingly.

#### Root(ERC20/721/1155)Predicates

The RootPredicate contracts is part of a cross-chain bridge system, enabling token deposits and withdrawals from the root chain to the child chain. It serves as the "root" counterpart of the ChildPredicates, and it facilitates the creation and management of mappings between root and child tokens.
