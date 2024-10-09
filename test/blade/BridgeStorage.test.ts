import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { BLS, BN256G2, BridgeStorage } from "../../typechain-types";
import * as mcl from "../../ts/mcl";
import { BigNumberish } from "ethers";
import {
  SignedBridgeMessageBatchStruct,
  SignedBridgeMessageBatchStructOutput,
} from "../../typechain-types/contracts/blade/BridgeStorage";

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["DOMAIN_BRIDGE"]));
const sourceChainId = 2;
const destinationChainId = 3;

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
  });

  it("Bridge storage fail: no system call", async () => {
    const batch: SignedBridgeMessageBatchStruct = {
      rootHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      startId: 1,
      endId: 5,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
      signature: [100, 200],
      bitmap: "0xffff",
    };

    await expect(bridgeStorage.commitBatch(batch))
      .to.be.revertedWithCustomError(bridgeStorage, "Unauthorized")
      .withArgs("SYSTEMCALL");
  });

  it("Bridge storage commitBatch fail: invalid signature", async () => {
    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;

    const batch: SignedBridgeMessageBatchStruct = {
      rootHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      startId: 1,
      endId: 5,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
      signature: [100, 200],
      bitmap: bitmap,
    };

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

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("SIGNATURE_VERIFICATION_FAILED");
  });

  it("Bridge storage commitBatch fail: empty bitmap", async () => {
    const bitmapStr = "00";

    const bitmap = `0x${bitmapStr}`;

    const batch: SignedBridgeMessageBatchStruct = {
      rootHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      startId: 1,
      endId: 5,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
      signature: [0, 0],
      bitmap: bitmap,
    };

    const messageOfBatch = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "uint256", "uint256", "uint256", "uint256"],
        [batch.rootHash, batch.startId, batch.endId, batch.sourceChainId, batch.destinationChainId]
      )
    );

    const message = ethers.utils.defaultAbiCoder.encode(["bytes32"], [messageOfBatch]);

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

    batch.signature = aggMessagePoint;

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("BITMAP_IS_EMPTY");
  });

  it("Bridge storage commitBatch fail:not enough voting power", async () => {
    const bitmapStr = "01";

    const bitmap = `0x${bitmapStr}`;

    const batch: SignedBridgeMessageBatchStruct = {
      rootHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      startId: 1,
      endId: 5,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
      signature: [0, 0],
      bitmap: bitmap,
    };

    const messageOfBatch = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "uint256", "uint256", "uint256", "uint256"],
        [batch.rootHash, batch.startId, batch.endId, batch.sourceChainId, batch.destinationChainId]
      )
    );

    const message = ethers.utils.defaultAbiCoder.encode(["bytes32"], [messageOfBatch]);

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

    batch.signature = aggMessagePoint;

    await expect(systemBridgeStorage.commitBatch(batch)).to.be.revertedWith("INSUFFICIENT_VOTING_POWER");
  });

  it("Bridge storage commitBatch success", async () => {
    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;

    const batch: SignedBridgeMessageBatchStruct = {
      rootHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
      startId: 1,
      endId: 5,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
      signature: [0, 0],
      bitmap: bitmap,
    };

    const messageOfBatch = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "uint256", "uint256", "uint256", "uint256"],
        [batch.rootHash, batch.startId, batch.endId, batch.sourceChainId, batch.destinationChainId]
      )
    );

    const message = ethers.utils.defaultAbiCoder.encode(["bytes32"], [messageOfBatch]);

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

    batch.signature = aggMessagePoint;

    const firstTx = await systemBridgeStorage.commitBatch(batch);
    const firstReceipt = await firstTx.wait();
    const firstLogs = firstReceipt?.events?.filter((log) => log.event === "NewBatch") as any[];
    expect(firstLogs).to.exist;
  });
});
