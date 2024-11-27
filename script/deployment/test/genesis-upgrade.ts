// Genesis EpochManager upgrade example
// Contract is extended with 'string private _version = "V2"' and methods:
// function setVersion(string memory version) external virtual
// function getVersion() external view virtual returns (string memory)
// In order to run script do following steps:
// 1. npx hardhat compile (to compile contracts)
// 2. npx hardhat run script/deployment/test/genesis-upgrade.ts (blade must be running and accounts should have tokens)

import "@nomiclabs/hardhat-ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";
import EpochManager from "../../../artifacts/contracts/blade/validator/EpochManager.sol/EpochManager.json";
import TUP from "../../../artifacts/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol/ITransparentUpgradeableProxy.json";

async function main() {
  const provider = new ethers.providers.JsonRpcProvider("http://localhost:10002");
  const user = new ethers.Wallet("b00ee7d037cd9ddd26866641bc2387059c0c8b2d86b7f1ef61d3a0956d21ab14", provider);
  const proxyAdmin = new ethers.Wallet("e77f21c7c2cc438846dcfdd269c68daea4c1c7f40d2c3329ea55c01e24f77bcc", provider);
  const proxyAddress = "0x0000000000000000000000000000000000000101";
  const implAddress = "0x0000000000000000000000000000000000001011";
  const storageSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbcn;

  const myContractFactory = new ethers.ContractFactory(EpochManager.abi, EpochManager.bytecode);
  const myContract = await myContractFactory.connect(user).deploy();
  await myContract.deployed();

  // direct call to deployed smart contract
  console.log("Contract call getVersion after deployment -> %s", await myContract.getVersion());

  // check v1 implementation address
  const v1Address = await provider.getStorageAt(proxyAddress, storageSlot);
  expect(BigNumber.from(v1Address)).equal(BigNumber.from(implAddress));

  // get TUP contract & call with admin for upgrade
  const tup = await ethers.getContractAt(TUP.abi, proxyAddress);
  const txn = await tup.connect(proxyAdmin).upgradeTo(myContract.address);
  await txn.wait();

  // check v2 implementation address
  const v2Address = await provider.getStorageAt(proxyAddress, storageSlot);
  expect(BigNumber.from(v2Address)).equal(myContract.address);

  // proxy get version
  const proxy = myContract.attach(tup.address);
  console.log("Proxy call getVersion after upgrade -> %s", await proxy.connect(user).getVersion());

  // proxy set/get version
  const txn1 = await proxy.connect(user).setVersion("V2");
  await txn1.wait();
  console.log("Proxy call getVersion after setting -> %s", await proxy.connect(user).getVersion());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
