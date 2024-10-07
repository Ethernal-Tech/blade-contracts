import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { BLS, BN256G2, Gateway } from "../../typechain-types";
import * as mcl from "../../ts/mcl";

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["DOMAIN_BRIDGE"]));
const sourceChainId = 2;
const destinationChainId = 3;

describe("Gateway", () => {
  let gateway: Gateway,
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

    const DestinationGateway = await ethers.getContractFactory("Gateway");
    gateway = (await DestinationGateway.deploy()) as Gateway;
    await gateway.deployed();

    const BLS = await ethers.getContractFactory("BLS");
    bls = (await BLS.deploy()) as BLS;
    await bls.deployed();

    const BN256G2 = await ethers.getContractFactory("BN256G2");
    bn256G2 = (await BN256G2.deploy()) as BN256G2;
    await bn256G2.deployed();

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

    await gateway.initialize(bls.address, bn256G2.address, validatorSet);
  });

  it("Gateway: should set initial params properly", async () => {
    expect(await gateway.counter()).to.equal(0);
  });

  it("Gateway: should check receiver address", async () => {
    const maxDataLength = (await gateway.MAX_LENGTH()).toNumber();
    const moreThanMaxData = "0x" + "00".repeat(maxDataLength + 1); // notice `+ 1` here (it creates more than max data)
    const receiver = "0x0000000000000000000000000000000000000000";

    await expect(gateway.sendBridgeMsg(receiver, moreThanMaxData, 1)).to.be.revertedWith("INVALID_RECEIVER");
  });

  it("Gateway: should check data length", async () => {
    const maxDataLength = (await gateway.MAX_LENGTH()).toNumber();
    const moreThanMaxData = "0x" + "00".repeat(maxDataLength + 1); // notice `+ 1` here (it creates more than max data)
    const receiver = accounts[2].address;

    await expect(gateway.sendBridgeMsg(receiver, moreThanMaxData, 1)).to.be.revertedWith("EXCEEDS_MAX_LENGTH");
  });

  it("Gateway: should emit event properly", async () => {
    const maxDataLength = (await gateway.MAX_LENGTH()).toNumber();
    const maxData = "0x" + "00".repeat(maxDataLength);
    const sender = accounts[0].address;
    const receiver = accounts[1].address;

    const tx = await gateway.sendBridgeMsg(receiver, maxData, 1);
    const receipt = await tx.wait();
    expect(receipt.events?.length).to.equals(1);

    const event = receipt.events?.find((log) => log.event === "BridgeMsg");
    expect(event?.args?.id).to.equal(1);
    expect(event?.args?.sender).to.equal(sender);
    expect(event?.args?.receiver).to.equal(receiver);
    expect(event?.args?.data).to.equal(maxData);
  });

  it("Gateway: should increase counter properly", async () => {
    const maxDataLength = (await gateway.MAX_LENGTH()).toNumber();
    const maxData = "0x" + "00".repeat(maxDataLength);
    const moreThanMaxData = "0x" + "00".repeat(maxDataLength + 1);
    const receiver = accounts[1].address;

    const initialCounter = (await gateway.counter()).toNumber();
    expect(await gateway.counter()).to.equal(initialCounter);

    await gateway.sendBridgeMsg(receiver, maxData, 1);
    await gateway.sendBridgeMsg(receiver, maxData, 1);
    await expect(gateway.sendBridgeMsg(receiver, moreThanMaxData, 1)).to.be.revertedWith("EXCEEDS_MAX_LENGTH");
    await gateway.sendBridgeMsg(receiver, maxData, 1);
    await expect(gateway.sendBridgeMsg(receiver, moreThanMaxData, 1)).to.be.revertedWith("EXCEEDS_MAX_LENGTH");

    expect(await gateway.counter()).to.equal(initialCounter + 3);
  });

  it("Gateway receiveBatch fail: invalid signature", async () => {
    msgs = [];

    msgs = [
      {
        id: 1,
        sourceChainId: sourceChainId,
        destinationChainId: destinationChainId,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
      {
        id: 2,
        sourceChainId: sourceChainId,
        destinationChainId: destinationChainId,
        sender: ethers.constants.AddressZero,
        receiver: ethers.constants.AddressZero,
        payload: ethers.constants.HashZero,
      },
    ];

    const bitmapStr = "ffff";

    const bitmap = `0x${bitmapStr}`;

    const batch = {
      messages: msgs,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
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

    await expect(gateway.receiveBatch(batch, aggMessagePoint, bitmap)).to.be.revertedWith(
      "SIGNATURE_VERIFICATION_FAILED"
    );
  });

  it("Gateway receiveBatch fail: empty bitmap", async () => {
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

    const batch = {
      messages: msgs,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
    };

    const messageOfBatch = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "tuple(uint256 id, uint256 sourceChainId, uint256 destinationChainId, address sender, address receiver, bytes payload)[]",
          "uint256",
          "uint256",
        ],
        [batch.messages, batch.sourceChainId, batch.destinationChainId]
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

    await expect(gateway.receiveBatch(batch, aggMessagePoint, bitmap)).to.be.revertedWith("BITMAP_IS_EMPTY");
  });

  it("Gateway receiveBatch fail:not enough voting power", async () => {
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

    const batch = {
      messages: msgs,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
    };

    const messageOfBatch = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "tuple(uint256 id, uint256 sourceChainId, uint256 destinationChainId, address sender, address receiver, bytes payload)[]",
          "uint256",
          "uint256",
        ],
        [batch.messages, batch.sourceChainId, batch.destinationChainId]
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

    await expect(gateway.receiveBatch(batch, aggMessagePoint, bitmap)).to.be.revertedWith("INSUFFICIENT_VOTING_POWER");
  });

  it("Gateway receiveBatch success", async () => {
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

    const batch = {
      messages: msgs,
      sourceChainId: sourceChainId,
      destinationChainId: destinationChainId,
    };

    const messageOfBatch = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        [
          "tuple(uint256 id, uint256 sourceChainId, uint256 destinationChainId, address sender, address receiver, bytes payload)[]",
          "uint256",
          "uint256",
        ],
        [batch.messages, batch.sourceChainId, batch.destinationChainId]
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

    const firstTx = await gateway.receiveBatch(batch, aggMessagePoint, bitmap);
    const firstReceipt = await firstTx.wait();
    const firstLogs = firstReceipt?.events?.filter((log) => log.event === "BridgeMessageResult") as any[];
    expect(firstLogs).to.exist;
  });

  it("Gateway receiveBatch fail: zero messages in batch", async () => {
    msgs = [];

    let sign: [number, number];

    sign = [1, 1];

    const batch = {
      messages: msgs,
      sourceChainId: 2,
      destinationChainId: 3,
    };

    await expect(gateway.receiveBatch(batch, sign, ethers.constants.AddressZero)).to.be.revertedWith("EMPTY_BATCH");
  });

  it("Gateway receiveBatch fail: bad source chain id", async () => {
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
    ];

    let sign: [number, number];

    sign = [0, 0];

    const batch = {
      messages: msgs,
      sourceChainId: 2,
      destinationChainId: 3,
    };

    await expect(gateway.receiveBatch(batch, sign, ethers.constants.AddressZero)).to.be.revertedWith(
      "INVALID_SOURCE_CHAIN_ID"
    );
  });
});
