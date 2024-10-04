/* eslint-disable node/no-unpublished-import */
import { ethers } from "hardhat";
import {
  CheckpointManager,
  StateSender,
  RootERC20Predicate,
  ChildMintableERC20Predicate,
  RootERC721Predicate,
  ChildMintableERC721Predicate,
  RootERC1155Predicate,
  ChildMintableERC1155Predicate,
} from "../typechain-types";

import fs from "fs";

type Config = {
  chainId: number;
  childERC20Predicate: string;
  childERC721Predicate: string;
  childERC1155Predicate: string;
  childTokenTemplate: string;
  nativeTokenRoot: string;
};

/**
 * Deploys common contracts: Merkle, BLS, and BN256G2.
 *
 * This function deploys three smart contracts: Merkle, BLS, and BN256G2.
 * It logs the deployed addresses of each contract and returns the addresses
 * of the BLS and BN256G2 contracts.
 *
 * @returns {Promise<[string, string]>} A promise that resolves to a tuple containing
 * the addresses of the deployed BLS and BN256G2 contracts.
 */
async function deployCommonContracts(): Promise<[string, string]> {
  const Merkle = await ethers.getContractFactory("Merkle");
  const merkle = await Merkle.deploy();
  await merkle.deployed();
  console.log("Merkle deployed to:", merkle.address);

  const BLS = await ethers.getContractFactory("BLS");
  const bls = await BLS.deploy();
  await bls.deployed();
  console.log("BLS deployed to:", merkle.address);

  const BN256G2 = await ethers.getContractFactory("BN256G2");
  const bn256 = await BN256G2.deploy();
  await bn256.deployed();
  console.log("BN256G2 deployed to:", bn256.address);

  return [bls.address, bn256.address];
}

/**
 * Deploys new bridge contracts including StateSender, CheckpointManager, and ExitHelper.
 *
 * @param {string} initiator - The address of the initiator.
 * @param {string} bls - The BLS public key.
 * @param {string} bn256 - The BN256 public key.
 * @param {Config} config - The configuration object containing chainId and other parameters.
 * @returns {Promise<[string, string, string]>} A promise that resolves to an array containing the addresses of the deployed contracts: [StateSender, CheckpointManager, ExitHelper].
 */
async function deployNewBridgeContracts(
  initiator: string,
  bls: string,
  bn256: string,
  config: Config
): Promise<[string, string, string]> {
  const StateSender = await ethers.getContractFactory("StateSender");
  const stateSender = (await StateSender.deploy()) as StateSender;
  await stateSender.deployed();
  console.log("StateSender deployed to:", stateSender.address);

  const CheckpointManager = await ethers.getContractFactory("CheckpointManager");
  const checkpointManager = (await CheckpointManager.deploy(initiator)) as CheckpointManager;
  await checkpointManager.deployed();
  console.log("CheckpointManager deployed to:", checkpointManager.address);
  checkpointManager.initialize(bls, bn256, config.chainId, []);

  const ExitHelper = await ethers.getContractFactory("ExitHelper");
  const exitHelper = await ExitHelper.deploy();
  await exitHelper.deployed();
  console.log("ExitHelper deployed to:", exitHelper.address);
  exitHelper.initialize(checkpointManager.address);

  return [stateSender.address, checkpointManager.address, exitHelper.address];
}

/**
 * Deploys and initializes bridge token contracts for ERC20, ERC721, and ERC1155 tokens.
 *
 * @param stateSender - The address of the state sender contract.
 * @param checkpointManager - The address of the checkpoint manager contract.
 * @param exitHelper - The address of the exit helper contract.
 * @param config - Configuration object containing addresses for child predicates and token templates.
 * @param config.childERC20Predicate - The address of the child ERC20 predicate contract.
 * @param config.childTokenTemplate - The address of the child token template contract.
 * @param config.nativeTokenRoot - The address of the native token root contract.
 * @param config.childERC721Predicate - The address of the child ERC721 predicate contract.
 * @param config.childERC1155Predicate - The address of the child ERC1155 predicate contract.
 *
 * @returns A promise that resolves when all contracts are deployed and initialized.
 */
async function deployBridgeTokenContracts(
  stateSender: string,
  checkpointManager: string,
  exitHelper: string,
  config: Config
) {
  // Deploy and initialize ERC20 token root contract predicate
  const RootERC20Predicate = await ethers.getContractFactory("RootERC20Predicate");
  const rootERC20Predicate = (await RootERC20Predicate.deploy()) as RootERC20Predicate;
  await rootERC20Predicate.deployed();
  console.log("RootERC20Predicate deployed to:", rootERC20Predicate.address);
  await rootERC20Predicate.initialize(
    stateSender,
    exitHelper,
    config.childERC20Predicate,
    config.childTokenTemplate,
    config.nativeTokenRoot
  );

  // Deploy and initialize ERC20 token child mintable contract predicate
  const ChildMintableERC20Predicate = await ethers.getContractFactory("ChildMintableERC20Predicate");
  const childMintableERC20Predicate = (await ChildMintableERC20Predicate.deploy()) as ChildMintableERC20Predicate;
  await childMintableERC20Predicate.deployed();
  console.log("ChildMintableERC20Predicate deployed to:", childMintableERC20Predicate.address);
  await childMintableERC20Predicate.initialize(
    stateSender,
    checkpointManager,
    rootERC20Predicate.address,
    config.childERC20Predicate
  );

  // Deploy and initialize ERC721 token root contract predicate
  const RootERC721Predicate = await ethers.getContractFactory("RootERC721Predicate");
  const rootERC721Predicate = (await RootERC721Predicate.deploy()) as RootERC721Predicate;
  await rootERC721Predicate.deployed();
  console.log("RootERC721Predicate deployed to:", rootERC721Predicate.address);
  await rootERC721Predicate.initialize(stateSender, exitHelper, config.childERC721Predicate, config.childTokenTemplate);

  // Deploy and initialize ERC721 token child mintable contract predicate
  const ChildMintableERC721Predicate = await ethers.getContractFactory("ChildMintableERC721Predicate");
  const childMintableERC721Predicate = (await ChildMintableERC721Predicate.deploy()) as ChildMintableERC721Predicate;
  await childMintableERC721Predicate.deployed();
  console.log("ChildMintableERC721Predicate deployed to:", childMintableERC721Predicate.address);
  await childMintableERC721Predicate.initialize(
    stateSender,
    checkpointManager,
    rootERC721Predicate.address,
    config.childERC721Predicate
  );

  // Deploy and initialize ERC1155 token root contract predicate
  const RootERC1155Predicate = await ethers.getContractFactory("RootERC1155Predicate");
  const rootERC1155Predicate = (await RootERC1155Predicate.deploy()) as RootERC1155Predicate;
  await rootERC1155Predicate.deployed();
  console.log("RootERC1155Predicate deployed to:", rootERC1155Predicate.address);
  await rootERC1155Predicate.initialize(
    stateSender,
    exitHelper,
    config.childERC1155Predicate,
    config.childTokenTemplate
  );

  // Deploy and initialize ERC1155 token child mintable contract predicate
  const ChildMintableERC1155Predicate = await ethers.getContractFactory("ChildMintableERC1155Predicate");
  const childMintableERC1155Predicate = (await ChildMintableERC1155Predicate.deploy()) as ChildMintableERC1155Predicate;
  await childMintableERC1155Predicate.deployed();
  console.log("ChildMintableERC1155Predicate deployed to:", childMintableERC1155Predicate.address);
  await childMintableERC1155Predicate.initialize(
    stateSender,
    checkpointManager,
    rootERC1155Predicate.address,
    config.childERC1155Predicate
  );
}

/**
 * Main deployment script function.
 *
 * This function performs the following tasks:
 * 1. Retrieves the list of accounts from the ethers provider.
 * 2. Sets the initiator address to the first account's address.
 * 3. Loads the deployment configuration from a JSON file if it exists, otherwise uses default values.
 * 4. Deploys common contracts (BLS and BN256).
 * 5. Deploys new bridge contracts using the initiator address and the deployed common contracts.
 * 6. Deploys bridge token contracts using the newly deployed bridge contracts and the configuration.
 *
 * @returns {Promise<void>} A promise that resolves when the deployment process is complete.
 */
async function main() {
  const accounts = await ethers.getSigners();
  const initiator = accounts[0].address;
  const config: Config = fs.existsSync("deploymentConfig.json")
    ? (JSON.parse(fs.readFileSync("deploymentConfig.json", "utf-8")) as unknown as Config)
    : {
        chainId: 123,
        childERC20Predicate: ethers.Wallet.createRandom().address,
        childERC721Predicate: ethers.Wallet.createRandom().address,
        childERC1155Predicate: ethers.Wallet.createRandom().address,
        childTokenTemplate: ethers.Wallet.createRandom().address,
        nativeTokenRoot: ethers.Wallet.createRandom().address,
      };
  const [bls, bn256] = await deployCommonContracts();
  const [stateSender, checkpointManager, exitHelper] = await deployNewBridgeContracts(initiator, bls, bn256, config);
  await deployBridgeTokenContracts(stateSender, checkpointManager, exitHelper, config);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
