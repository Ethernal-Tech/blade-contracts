import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { BLS, BN256G2, ValidatorSetStorage } from "../../typechain-types";
import * as mcl from "../../ts/mcl";

const DOMAIN_VALIDATOR_SET = ethers.utils.arrayify(
  ethers.utils.solidityKeccak256(["string"], ["DOMAIN_VALIDATOR_SET"])
);

describe("BaseBridgeGateway", () => {
  let validatorSetStorage: ValidatorSetStorage,
    systemValidatorSetStorage: ValidatorSetStorage,
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

    const BaseBridgeGateway = await ethers.getContractFactory("ValidatorSetStorage");
    validatorSetStorage = (await BaseBridgeGateway.deploy()) as ValidatorSetStorage;
    await validatorSetStorage.deployed();

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
    systemValidatorSetStorage = validatorSetStorage.connect(systemSigner);
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

    await expect(validatorSetStorage.initialize(bls.address, bn256G2.address, validatorSet)).to.be.revertedWith(
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

    await validatorSetStorage.initialize(bls.address, bn256G2.address, validatorSet);
    expect(await validatorSetStorage.bls()).to.equal(bls.address);
    expect(await validatorSetStorage.bn256G2()).to.equal(bn256G2.address);
    expect(await validatorSetStorage.currentValidatorSetLength()).to.equal(validatorSetSize);

    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await validatorSetStorage.currentValidatorSet(i);
      expect(validator._address).to.equal(accounts[i].address);
      expect(validator.votingPower).to.equal(ethers.utils.parseEther(((i + 1) * 2).toString()));
    }
  });

  it("Base bridge gateway fail: no system call", async () => {
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

    await expect(validatorSetStorage.commitValidatorSet(validatorSet, sign, ethers.constants.AddressZero))
      .to.be.revertedWithCustomError(validatorSetStorage, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("Bridge storage commitValidator success", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12
    const bitmap = "0xffff";

    let validatorSetTmp = [];
    let validatorSecretKeysTmp = [];

    for (let i = 0; i < validatorSetSize; i++) {
      const { pubkey, secret } = mcl.newKeyPair();
      validatorSecretKeysTmp.push(secret);
      validatorSetTmp.push({
        _address: accounts[i].address,
        blsKey: mcl.g2ToHex(pubkey),
        votingPower: ethers.utils.parseEther(((i + 1) * 2).toString()),
      });
    }

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
        [validatorSetTmp]
      )
    );

    const signatures: mcl.Signature[] = [];

    let aggVotingPower = 0;
    for (let i = 0; i < validatorSecretKeys.length; i++) {
      const byteNumber = Math.floor(i / 8);
      const bitNumber = i % 8;

      if (byteNumber >= bitmap.length / 2 - 1) {
        continue;
      }

      // Get the value of the bit at the given 'index' in a byte.
      const oneByte = parseInt(bitmap[2 + byteNumber * 2] + bitmap[3 + byteNumber * 2], 16);
      if ((oneByte & (1 << bitNumber)) > 0) {
        const { signature, messagePoint } = mcl.sign(
          message,
          validatorSecretKeys[i],
          ethers.utils.arrayify(DOMAIN_VALIDATOR_SET)
        );
        signatures.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const firstTx = await systemValidatorSetStorage.commitValidatorSet(validatorSetTmp, aggMessagePoint, bitmap);
    const firstReceipt = await firstTx.wait();
    const firstLogs = firstReceipt?.events?.filter(
      (log) => log.event === "NewValidatorSet"
    ) as any[];
    expect(firstLogs).to.exist;
  });

  it("Base bridge gateway commitValidatorSet fail: empty validator set", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12

    validatorSet = [];

    let sign: [number, number];

    sign = [0, 0];

    await expect(
      systemValidatorSetStorage.commitValidatorSet(validatorSet, sign, ethers.constants.AddressZero)
    ).to.be.revertedWith("EMPTY_VALIDATOR_SET");
  });
});
