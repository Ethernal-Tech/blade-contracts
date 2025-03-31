# Bridge

## Bridge contracts provide bridge functionality

### Internal

This directory contains contracts meant for usage on blade chain.

#### BridgeStorage

The BridgeStorage contract is a fundamental component of a multi-chain bridge protocol, primarily focused on storing and managing signed bridge message batches that enable secure cross-chain communication. It extends ValidatorSetStorage, which is essential for verifying signatures on committed batches, ensuring the integrity and reliability of both message batches and validator set updates.

#### ValidatorSetStorage

The ValidatorSetStorage contract is responsible for storing and updating validator sets used for validating cross-chain transactions. It verifies validator signatures using BLS (Boneh-Lynn-Shacham) cryptography, ensuring that changes to the validator set meet the required quorum before being committed.

#### Token contracts

The `ChildERC20`, `ChildERC721`, `ChildERC1155` contracts represent templates for the management of bridged assets on the blade chain.

### Common

This directory contains contracts meant for usage on both Internal(blade) and external chains.

#### Gateway

The Gateway contract is a core component of a blockchain bridge system, responsible for handling message passing between different blockchain networks. In some cases it interacts with the BridgeStorage contract and facilitates state synchronization through events.

#### BladeManager

The BladeManager contract is a critical component of the blockchain bridge system, responsible for managing the genesis state and token balances during the initial phase of a new blockchain network. It facilitates the allocation of premined and staked tokens, ensures validator participation, and interacts with the RootERC20Predicate contract to lock native tokens on the root chain. Additionally, it enforces access control mechanisms and prevents unauthorized actions during the genesis phase.

#### TestRollbackGateway

The TestRollbackGateway contract extends the Gateway contract and is designed to simulate and test the handling of rollback operations in the blockchain bridge system. It overrides the receiveBatch function to process a batch of messages. For each message, the contract either executes the bridge message or simulates a rollback if the message ID is even, emitting the corresponding result.

#### Predicate contracts

The predicate contracts provide an interface for the bridge to manage transactions involving assets of their respective standards. These are provided in two forms, a regular template and access list version. Supernets can be made permissioned, and the access list versions of the predicate check to see if the address interacting with the bridge has the permissions to do so using either an inclusionary list (AllowList) or exclusionary list (BlockList). Usage of these lists can be turned off at any time by the Supernet's administrators.
