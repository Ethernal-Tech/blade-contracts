import { expect } from "chai";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { BLS, BN256G2, DestinationGateway } from "../../typechain-types";
import * as mcl from "../../ts/mcl";
import { bridge } from "../../typechain-types/contracts";

const DOMAIN = ethers.utils.arrayify(ethers.utils.solidityKeccak256(["string"], ["DOMAIN_BRIDGE"]));
const sourceChainId = 2;
const destinationChainId = 3;

describe("DestinationGateway", () => {
  let destinationGateway: DestinationGateway,
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

    const DestinationGateway = await ethers.getContractFactory("DestinationGateway");
    destinationGateway = (await DestinationGateway.deploy()) as DestinationGateway;
    await destinationGateway.deployed();

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

    await destinationGateway.initialize(bls.address, bn256G2.address, validatorSet);
  });

  it("Destination gateway receiveBatch fail: invalid signature", async () => {
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

    await expect(destinationGateway.receiveBatch(batch, aggMessagePoint, bitmap)).to.be.revertedWith(
      "SIGNATURE_VERIFICATION_FAILED"
    );
  });

  it("Destination gateway receiveBatch fail: empty bitmap", async () => {
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
          "tuple(tuple(uint256 id, uint256 sourceChainId, uint256 destinationChainId, address sender, address receiver, bytes payload)[] messages, uint256 sourceChainId, uint256 destinationChainId)",
        ],
        [batch]
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

    await expect(destinationGateway.receiveBatch(batch, aggMessagePoint, bitmap)).to.be.revertedWith("BITMAP_IS_EMPTY");
  });

  it("Destination gateway receiveBatch fail:not enough voting power", async () => {
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
          "tuple(tuple(uint256 id, uint256 sourceChainId, uint256 destinationChainId, address sender, address receiver, bytes payload)[] messages, uint256 sourceChainId, uint256 destinationChainId)",
        ],
        [batch]
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

    await expect(destinationGateway.receiveBatch(batch, aggMessagePoint, bitmap)).to.be.revertedWith(
      "INSUFFICIENT_VOTING_POWER"
    );
  });

  it("Destination gateway commitBatch success", async () => {
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
          "tuple(tuple(uint256 id, uint256 sourceChainId, uint256 destinationChainId, address sender, address receiver, bytes payload)[] messages, uint256 sourceChainId, uint256 destinationChainId)",
        ],
        [batch]
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

    const firstTx = await destinationGateway.receiveBatch(batch, aggMessagePoint, bitmap);
    const firstReceipt = await firstTx.wait();
    const firstLogs = firstReceipt?.events?.filter((log) => log.event === "BridgeMessageResult") as any[];
    expect(firstLogs).to.exist;
  });

  it("Destination gateway receiveBatch fail: zero messages in batch", async () => {
    msgs = [];

    let sign: [number, number];

    sign = [1, 1];

    const batch = {
      messages: msgs,
      sourceChainId: 2,
      destinationChainId: 3,
    };

    await expect(destinationGateway.receiveBatch(batch, sign, ethers.constants.AddressZero)).to.be.revertedWith(
      "EMPTY_BATCH"
    );
  });

  it("Destination gateway receiveBatch fail: bad source chain id", async () => {
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

    await expect(destinationGateway.receiveBatch(batch, sign, ethers.constants.AddressZero)).to.be.revertedWith(
      "INVALID_SOURCE_CHAIN_ID"
    );
  });
});