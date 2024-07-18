import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { BLS, BN256G2,BaseBridgeGateway } from "../../typechain-types";
import * as mcl from "../../ts/mcl";
import { bridge } from "../../typechain-types/contracts";

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["DOMAIN_BRIDGE"]));

describe("BridgeStorage", () => {
  let baseBridgeGateway: BaseBridgeGateway,
    systemBaseBridgeGateway: BaseBridgeGateway,
    msgs: any[],
    bls: BLS,
    bn256G2: BN256G2,
    validatorSetSize: number,
    validatorSecretKeys: any[],
    validatorSet: any[],
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    const BaseBridgeGateway = await ethers.getContractFactory("BridgeStorage");
    baseBridgeGateway = (await BaseBridgeGateway.deploy()) as BaseBridgeGateway;
    await baseBridgeGateway.deployed();

    const BLS = await ethers.getContractFactory("BLS");
    bls = (await BLS.deploy()) as BLS;
    await bls.deployed();

    const BN256G2 = await ethers.getContractFactory("BN256G2");
    bn256G2 = (await BN256G2.deploy()) as BN256G2;
    await bn256G2.deployed();

    await hre.network.provider.send("hardhat_setBalance", [
      "0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.send("hardhat_setBalance", [
      "0x0000000000000000000000000000000000001001",
      "0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    ]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE"],
    });
    const systemSigner = await ethers.getSigner("0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE");
    systemBaseBridgeGateway = baseBridgeGateway.connect(systemSigner);
  });

  it("Initialize failed by zero voting power", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12

    validatorSecretKeys = [];
    validatorSet = [];
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      validatorSecretKeys.push(secret);
      validatorSet.push({
        _address: accounts[i].address,
        blsKey: mcl.g2ToHex(pubkey),
        votingPower: 0,
      });
    }

    await expect(baseBridgeGateway.initialize(bls.address, bn256G2.address, validatorSet)).to.be.revertedWith(
      "VOTING_POWER_ZERO"
    );
  });

  it("Initialize and validate initialization", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12

    validatorSecretKeys = [];
    validatorSet = [];
    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      validatorSecretKeys.push(secret);
      validatorSet.push({
        _address: accounts[i].address,
        blsKey: mcl.g2ToHex(pubkey),
        votingPower: ethers.utils.parseEther(((i + 1) * 2).toString()),
      });
    }

    await baseBridgeGateway.initialize(bls.address, bn256G2.address, validatorSet);
    expect(await baseBridgeGateway.bls()).to.equal(bls.address);
    expect(await baseBridgeGateway.bn256G2()).to.equal(bn256G2.address);
    expect(await baseBridgeGateway.currentValidatorSetLength()).to.equal(validatorSetSize);

    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await baseBridgeGateway.currentValidatorSet(i);
      expect(validator._address).to.equal(accounts[i].address);
      expect(validator.votingPower).to.equal(ethers.utils.parseEther(((i + 1) * 2).toString()));
    }
  });

  it("Bridge storage fail: no system call", async () => {
    msgs = [];

    msgs = [
      {
        id: 1,
        sourceChainId: 2,
        destinationChainId: 3,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
    ];

    let sign: [number, number];

    sign = [1, 1];

    await expect(baseBridgeGateway.commitValidatorSet(validatorSet, sign, ethers.constants.AddressZero))
      .to.be.revertedWithCustomError(baseBridgeGateway, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("Bridge storage commitValidatorSet fail: empty validator set", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12

    validatorSet = [];

    let sign: [number, number];

    sign = [0, 0];

    await expect(
      systemBaseBridgeGateway.commitValidatorSet(validatorSet, sign, ethers.constants.AddressZero)
    ).to.be.revertedWith("EMPTY_VALIDATOR_SET");
  });
});
