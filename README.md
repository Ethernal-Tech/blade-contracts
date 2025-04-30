# Core Contracts

[![Solidity CI](https://github.com/maticnetwork/v3-contracts/actions/workflows/ci.yml/badge.svg)](https://github.com/maticnetwork/v3-contracts/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/maticnetwork/v3-contracts/badge.svg?branch=main&t=ZTUm69)](https://coveralls.io/github/maticnetwork/v3-contracts?branch=main)

This repository contains the smart contract suite used in Polygon's ecosystems. Recent iterations have focused on features for the Edge project. Edge-specific contracts may be spun off into their own repo in the future.

**_Note: You do not need to clone this repo in order to interact with Polygon POS or any other Polygon ecosystem._**

## Contents

- [Core Contracts](#core-contracts)
  - [Contents](#contents)
  - [Repo Architecture](#repo-architecture)
    - [Contracts](#contracts)
    - [General Repo Layout](#general-repo-layout)
  - [Using This Repo](#using-this-repo)
    - [Requirements](#requirements)
    - [General Repo Layout](#general-repo-layout-1)
    - [Installation](#installation)
    - [Deployment](#deployment)
      - [Root contracts](#root-contracts)
    - [Environment Setup](#environment-setup)
    - [Compiling Contracts](#compiling-contracts)
    - [Running tests](#running-tests)
    - [Linting](#linting)
    - [Check Test Coverage](#check-test-coverage)
    - [Run Slither](#run-slither)
    - [Continuous Integration](#continuous-integration)
    - [Documentation](#documentation)

## Repo Architecture

### Contracts

There are a number of different contracts with different roles in the suite, as such an architecture diagram of the contents of `contracts/` should be useful in understanding where to find what you're looking for.

One piece of terminology that is useful in understanding the layout and contracts themselves is the references to `root` and `child`. Chains such as POS and Edge assume that there is a base layer chain that data from other chains is committed to. In the case of POS, the root chain is Ethereum mainnet and the child is Polygon POS, while in the case of Edge, the root chain is Edge and the child chains are the various Supernets.

```ml
│ blade/ – "Contracts that live on the Blade chain"
├─ tokens – "Contracts for bridging and managing native, ERC20, ERC721, and ERC1155 assets"
├─ EIP1559Burn – "Enables the child native token to be burned on the root chain"
├─ ForkParams – "Configurable soft fork features read by the client each epoch"
├─ NetworkParams – "Configurable network parameters read by the client each epoch"
├─ staking/ – "Contracts comprising the hub for staking on any child chain"
│  └─ StakeManager – "Manages stake for all child chains"
├─ System/ – "Various infrastructure/precompile addresses on the child chain"
├─ validator/ – "Contracts directly related to validation"
│  ├─ RewardPool – "Distributes rewards to validators for committed epochs"
│  └─ ValidatorSet – "Manages validator voting power and commits epochs for child chains"

│ common/ – "Libraries used on both the child and root chains"
├─ BLS – "BLS signature operations"
├─ BN256G2 – "Elliptic curve operations on G2 for BN256 (used for BLS)"
├─ Merkle – "Checks membership of a hash in a Merkle tree"

│ interfaces/ – "Interfaces for all contracts"
├─ Errors – "Commonly reused errors"

│ lib/ – "Libraries used for specific applications"
├─ AccessList – "Checks address membership in protocol-level access controls"
├─ ChildManagerLib – "Library for managing child chains on the root chain"
├─ EIP712MetaTransaction – "Template for processing EIP-712 structures"
├─ EIP712Upgradeable – "Adapted from OpenZeppelin; supports upgradeable EIP-712 structures"
├─ GenesisLib – "Facilitates generation of the validator set at genesis"
├─ ModExp – "Modular exponentiation (from the Hubble Project, used for BLS)"
├─ SafeMathInt – "Casts between int256 and uint256 with overflow/underflow checks"
├─ StakeManagerLib – "Handles validator staking logic (deposit, withdrawal, etc.)"
├─ WithdrawalQueue – "Library for operations related to the rewards withdrawal queue"

│ mocks/ – "Mocks of various contracts for testing"

│ bridge/common/ – "Contracts used on both chains"
├─ root predicates/ – "Templates for processing asset bridging on the root chain"
├─ child predicates/ – "Templates for processing asset bridging on the child chain"
├─ Gateway – "Sends messages on the source chain and executes them on the destination chain"
├─ TestRollbackGateway – "Test contract used only for testing purposes"

│ bridge/internal/ – "Contracts used on the Blade chain only"
├─ BridgeStorage – "Storage for bridge batches"
├─ ValidatorSetStorage – "Stores the latest validator set; used for checking batch signatures"
```

### General Repo Layout

This repo is a hybrid [Hardhat](https://hardhat.org) and [Foundry](https://getfoundry.sh/) environment. There are a number of add-ons, some of which we will detail here. Unlike standard Foundry environments, the contracts are located in `contracts/` (as opposed to `src/`) in order to conform with the general Hardhat project architecture. The Foundry/Solidity tests live in `test/forge/` whereas the Hardhat/Typescript tests are at the root level of `test/`. (For more details on the tests, see [Running Tests](#running-tests) in the [Using This Repo](#using-this-repo) section.) This can result in the actual test coverage on the repo being hard to read, as `solidity-coverage` and Foundry's native coverage tools do not natively communicate with each other. (In addition, Foundry's tool does not currently reflect branch coverage in Solidity libraries properly ([source](https://github.com/foundry-rs/foundry/issues/4854)), though this will likely be remediated in the future.)

Part of the rationale is that while Foundry provides a set of options well suited to testing bridges, there are still aspects of the codebase which cannot be tested in native Solidity, particularly

The following is a brief overview of some of the files and directories in the project root:

```ml
│ .github/workflows/ - "CI (Github Actions) script: formats, lints, runs tests, coverage, Slither"
│ contracts/ - "all smart contracts, including mocks, but excluding Foundry tests and libs"
│ docs/ - "smart contract docs autogenerated from natspec"
│ lib/ - "smart contract libraries utilized by Foundry"
│ scripts/ - "Hardhat scripts, currently not updated, may contain deployment scripts in the future"
│ test/ - "both HH/TS and Foundry/Sol tests"
│ ts/ - "Typescript libraries for BLS/Elliptic Curves for testing BLS/BN256G2"
│ types/ - "Typescript types"
│ .env.example - "example env var file for using the HH env to connect with public nets/testnets"
│ .eslint.js - "JavaScript/TypeScript linter settings"
│ .nvmrc - "recommended Node version using nvm"
│ .prettierrc - "code formatting settings"
│ .solcover.js - "solidity-coverage settings"
│ .solhint.json - "Solidity linter settings"
│ foundry.toml - "Foundry configuration file"
│ hardhat.config.ts - "Hardhat configuration file"
│ slither.config.json - "settings for the Slither static analyzer"
```

The `package-lock.json` is also provided to ensure the ability to install the same versions of the npm packages used in development and testing.

## Using This Repo

### Requirements

In order to work with this repo locally, you will need Node (preferably using [nvm](https://github.com/nvm-sh/nvm)) in order to work with the Hardhat part of the repo.

In addition, to work with Foundry, you will need to have it installed. The recommended method is to use their `foundryup` tool, which can be installed (and automatically install Foundry) using this command:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Note that this only works on Linux and Mac. For Windows, or if `foundryup` doesn't work, consult [their documentation](https://book.getfoundry.sh/getting-started/installation).

### General Repo Layout

This repo is a hybrid [Hardhat](https://hardhat.org) and [Foundry](https://getfoundry.sh/) environment. There are a number of add-ons, some of which we will detail here. Unlike standard Foundry environments, the contracts are located in `contracts/` (as opposed to `src/`) in order to conform with the general Hardhat project architecture. The Foundry/Solidity tests live in `test/forge/` whereas the Hardhat/Typescript tests are at the root level of `test/`. (For more details on the tests, see [Running Tests](#running-tests) in the [Using This Repo](#using-this-repo) section.)

Install Foundry libs:

In addition, to work with Foundry, you will need to have it installed. The recommended method is to use their `foundryup` tool, which can be installed (and automatically install Foundry) using this command:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Note that this only works on Linux and Mac. For Windows, or if `foundryup` doesn't work, consult [their documentation](https://book.getfoundry.sh/getting-started/installation).

### Installation

**You do not need to clone this repo in order to interact with the Polygon core contracts**

If you would like to work with these contracts in a development environment, first clone the repo:

```bash
git clone git@github.com:maticnetwork/v3-contracts.git
```

If you have [nvm](https://github.com/nvm-sh/nvm) installed (recommended), you can run `nvm use #` to set your version of Node to the same as used in development and testing.

Install JS/TS (Hardhat) dependencies:

```bash
npm i
```

Install Foundry libs:

```bash
forge install
```

### Deployment

Deploying these contracts in the context of a production blockchain is out of the scope of this repo, as it requires a client that has support of the Edge specification integrated. At current, Edge maintains its own client [here](https://github.com/0xPolygon/polygon-edge), which can be consulted.

One point that is worth emphasizing in this context is that from the perspective of launching a Supernet is understanding genesis contracts. Another is that for at least the time being, the decision has been made to proxify all genesis contracts in order to facilitate upgrades/updates without necessitating a hardfork or regenesis. All deployment scripts in `script/deployment` use OpenZeppelin's `TransparentUpgradeableProxy`.

#### Root contracts

Deployment scripts have been provided for each of the root chain contracts. (The child chain contracts are genesis contracts, and are not deployed traditionally; they are deployed by the client as a part of the genesis of the child chain.)

Some contracts in the Edge suite need be deployed only once on root. These contracts can deployed using the [`DeployCommonContracts`](script/deployment/DeploySharedRootContracts.sol) script, after [`commonContractsConfig`](script/deployment/commonContractsConfig.json) has been filled with appropriate values.

Other contracts are deployed on root once per Supernet. These contracts can deployed using the [`DeployNewBridgeContractSet.s.sol`](script/deployment/DeployNewBridgeContractSet.s.sol) script, after [`bridgeContractSetConfig.json`](script/deployment/bridgeContractSetConfig.json) has been filled with appropriate values.

Note that the script does not initialize `CheckpointManager`. Instead, it protects it to be initializable only by the `INITIATOR` address later.

Not all root contracts are deployed at this point, however. There are parts of the bridge that need the addresses of various child contracts in order to be initialized. These contracts can deployed using the [`DeployBridgeTokenContracts.s.sol`](script/deployment/DeployBridgeTokenContracts.s.sol) script, after [`bridgeTokenContractsConfig.json`](script/deployment/bridgeTokenContractsConfig.json) has been filled with appropriate values.

Scripts are run by invoking:

```bash
forge <SCRIPT_NAME> \
  --broadcast \
  <SIGNING_METHOD> \
  --rpc-url <RPC_URL> \
  --verify \
  --sig "run()"
```

For the signing method and other options, consult [Foundry Book](https://book.getfoundry.sh/reference/forge/forge-script).

### Environment Setup

There are a few things that should be done to set up the repo once you've cloned it and installed the dependencies and libraries. An important step for various parts of the repo to work properly is to set up a `.env` file. There is an `.example.env` file provided, copy it and rename the copy `.env`.

The v3 contract set is meant to be deployed across two blockchains, which are called the root chain and child chain. In the case of Polygon POS v3 itself, Ethereum mainnet is the root chain, while Polygon POS v3 is the child chain. In order to give users the ability to work with these contracts on the chains of their choice, four networks are configured in Hardhat: `root`, `rootTest`, `child`, and `childTest`. To interact with whichever networks you would like to use as root and/or child, you will need to add a URL pointing to an RPC endpoint on the relevant chain in your `.env` file. This can be a RPC provider such as Ankr or Alchemy, in which case you would put the entire URL including the API key into the relevant line of the `.env`, or could be a local node, in which case you would put `https://localhost:<PORT_NUMBER>` (usually 8545).

A field for a private key is also provided in the `.env`. You will need to input this if you are interacting with any public networks (for example, deploying the contracts to a testnet).

Lastly, there are fields for an Etherscan and Polygonscan for verifying any deployed contracts on the Ethereum or Polygon mainnets or testnets. (Some additional configuration may be required, only Eth mainnet, Goerli, Polygon POS v1, and Mumbai are configured as of this writing.)

### Compiling Contracts

**Hardhat:**

```bash
npx hardhat compile --show-stack-traces
```

`hardhat-ts` automatically generates typings for you after compilation, to use in tests and scripts. You can import them like: `import { ... } from "../typechain-types";`

Similarly, the `hardhat-dodoc` package autogenerates smart contract documentation in `docs/` every time Hardhat compiles the contract. If you wish to disable this, uncomment the `runOnCompile: false` line in the `dodoc` object in `hardhat.config.ts`.

**Foundry:**

```bash
forge build
```

### Running tests

As mentioned previously, there are two separate test suites, one in Hardhat/Typescript, and the other in Foundry/Solidity. The HH tests are structured more as scenario tests, generally running through an entire interaction or process, while the Foundry tests are structured more as unit tests. This is coincidental, and is not a set rule.

**Hardhat:**

```bash
npx hardhat test
```

The Hardhat tests have gas reporting enabled by default, you can disable them from `hardhat.config.ts` by setting `enabled` in the `gasReporter` object in `hardhat.config.ts` or by setting `REPORT_GAS` to `false` in the `.env`.

**Foundry:**

```bash
forge test
```

Simple gas profiling is included in Foundry tests by default. For a more complete gas profile using Foundry, see [their documentation](https://book.getfoundry.sh/forge/gas-reports).

Simple gas profiling is included in Foundry tests by default. For a more complete gas profile using Foundry, see [their documentation](https://book.getfoundry.sh/forge/gas-reports).

### Linting

The linters run from inside the Hardhat/JS environment.

```bash
npm run lint      # runs all linters at once

npm run lint:sol  # only runs solhint and prettier
npm run lint:ts   # only runs prettier and eslint
```

### Check Test Coverage

We do not know of a way to see the general coverage from the TS and Solidity tests combined at this juncture. Instead, the coverage of each suite can be checked individually.

**Hardhat:**

```bash
npx hardhat coverage

# or

npm run coverage
```

**Foundry:**

```bash
forge coverage
```

### Run Slither

First, install slither by following the instructions [here](https://github.com/crytic/slither#how-to-install).
Then, run:

```bash
slither .

# or

npm run slither
```

### Continuous Integration

There is a CI script for Github Actions in `.github/workflows/`. Currently it runs:

- linters
- both test suites (fails if any tests fail)
- coverage report (currently only HH)
- Slither

### Documentation

This repo makes use of [Dodoc](https://github.com/primitivefinance/primitive-dodoc), a Hardhat plugin from Primitive Finance which generates Markdown docs on contracts from their natspec. The docs are generated on every compile, and can be found in the `docs/` directory.
