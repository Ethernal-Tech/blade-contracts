import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { BLS, BN256G2, BridgeStorage } from "../../typechain-types";
import * as mcl from "../../ts/mcl";
import { bridge } from "../../typechain-types/contracts";

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["DOMAIN_BRIDGE"]));

describe("BridgeStorage", () => {
  let bridgeStorage: BridgeStorage,
    msgs: any[],
    systemBridgeStorage: BridgeStorage,
    bls: BLS,
    bn256G2: BN256G2,
    validatorSetSize: number,
    validatorSecretKeys: any[],
    validatorSet: any[],
    accounts: any[]; // we use any so we can access address directly from object
  before(async () => {
    await mcl.init();
    accounts = await ethers.getSigners();

    const BridgeStorage = await ethers.getContractFactory("BridgeStorage");
    bridgeStorage = (await BridgeStorage.deploy()) as BridgeStorage;
    await bridgeStorage.deployed();

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
    systemBridgeStorage = bridgeStorage.connect(systemSigner);
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

    await expect(bridgeStorage.initialize(bls.address, bn256G2.address, validatorSet)).to.be.revertedWith(
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

    await bridgeStorage.initialize(bls.address, bn256G2.address, validatorSet);
    expect(await bridgeStorage.bls()).to.equal(bls.address);
    expect(await bridgeStorage.bn256G2()).to.equal(bn256G2.address);
    expect(await bridgeStorage.currentValidatorSetLength()).to.equal(validatorSetSize);

    for (let i = 0; i < validatorSetSize; i++) {
      const validator = await bridgeStorage.currentValidatorSet(i);
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

    const batch = {
      messages: msgs,
      signature: sign,
      bitmap: ethers.constants.AddressZero,
    };

    await expect(bridgeStorage.commitBatch(batch))
      .to.be.revertedWithCustomError(bridgeStorage, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("Bridge storage commitBatch fail: invalid signature", async () => {
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
      {
        id: 2,
        sourceChainId: 2,
        destinationChainId: 3,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
    ];

    let sign: [number, number];

    sign = [0, 0];

    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(["bytes32"], [ethers.utils.hexlify(ethers.utils.randomBytes(32))])
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
        const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(DOMAIN));
        signatures.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const batch = {
      messages: msgs,
      signature: aggMessagePoint,
      bitmap: bitmap,
    };

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });

  it("Bridge storage commitBatch fail: empty bitmap", async () => {
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
      {
        id: 2,
        sourceChainId: 2,
        destinationChainId: 3,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
    ];

    const bitmapStr = "00";

    const bitmap = `0x${bitmapStr}`;

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(["bytes32"], [await systemBridgeStorage.currentValidatorSetHash()])
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
        const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(DOMAIN));
        signatures.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const batch = {
      messages: msgs,
      signature: aggMessagePoint,
      bitmap: bitmap,
    };

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("BITMAP_IS_EMPTY");
  });

  it("Bridge storage commitBatch fail:not enough voting power", async () => {
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
      {
        id: 2,
        sourceChainId: 2,
        destinationChainId: 3,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
    ];

    const bitmapStr = "01";

    const bitmap = `0x${bitmapStr}`;

    const message = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(["bytes32"], [await systemBridgeStorage.currentValidatorSetHash()])
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
        const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(DOMAIN));
        signatures.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const batch = {
      messages: msgs,
      signature: aggMessagePoint,
      bitmap: bitmap,
    };

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("INSUFFICIENT_VOTING_POWER");
  });

  it("Bridge storage commitBatch success", async () => {
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
      {
        id: 2,
        sourceChainId: 2,
        destinationChainId: 3,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
    ];

    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;

    const validatorSetHash = await bridgeStorage.currentValidatorSetHash();

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
          validatorSetHash,
          validatorSecretKeys[i],
          ethers.utils.arrayify(DOMAIN)
        );
        signatures.push(signature);
        aggVotingPower += parseInt(ethers.utils.formatEther(validatorSet[i].votingPower), 10);
      } else {
        continue;
      }
    }

    const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));

    const batch = {
      messages: msgs,
      signature: aggMessagePoint,
      bitmap: bitmap,
    };

    const firstTx = await systemBridgeStorage.commitBatch(batch);
    const firstReceipt = await firstTx.wait();
    const firstLogs = firstReceipt?.events?.filter((log) => log.event === "NewBatch") as any[];
    expect(firstLogs).to.exist;
    expect(firstLogs[0]?.args?.id).to.equal(0);
  });

  it("Bridge storage commitBatch fail: zero messages in batch", async () => {
    msgs = [];

    let sign: [number, number];

    sign = [1, 1];

    const batch = {
      messages: msgs,
      signature: sign,
      bitmap: ethers.constants.AddressZero,
    };

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("EMPTY_BATCH");
  });

  it("Bridge storage bad commitBatch fail: bad source chain id", async () => {
    msgs = [];

    msgs = [
      {
        id: 1,
        sourceChainId: 1,
        destinationChainId: 3,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
      {
        id: 2,
        sourceChainId: 2,
        destinationChainId: 3,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
    ];

    let sign: [number, number];

    sign = [0, 0];

    const batch = {
      messages: msgs,
      signature: sign,
      bitmap: ethers.constants.AddressZero,
    };

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("INVALID_SOURCE_CHAIN_ID");
  });

  it("Bridge storage commitValidatorSet fail: empty validator set", async () => {
    validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12

    validatorSet = [];

    let sign: [number, number];

    sign = [0, 0];

    await expect(
      systemBridgeStorage.commitValidatorSet(validatorSet, sign, ethers.constants.AddressZero)
    ).to.be.revertedWith("EMPTY_VALIDATOR_SET");
  });
});
