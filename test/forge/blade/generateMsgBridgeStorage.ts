import { ethers } from "hardhat";
import * as mcl from "../../../ts/mcl";
const input = process.argv[2];

const sourceChainId = 2;
const destinationChainId = 3;

// let DOMAIN = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));
// let eventRoot = ethers.utils.arrayify(ethers.utils.hexlify(ethers.utils.randomBytes(32)));

let domain: any;

let validatorSecretKeys: any[] = [];
const validatorSetSize = Math.floor(Math.random() * (5 - 1) + 8); // Randomly pick 8 - 12
let aggMessagePoints: mcl.MessagePoint[] = [];
let accounts: any[] = [];
let validatorSet: any[] = [];
let eventRoot: any;
let blockHash: any;
let currentValidatorSetHash: any;
let bitmaps: any[] = [];
let aggVotingPowers: any[] = [];
let msgs = [
  {
    id: 1,
    sourceChainId: sourceChainId,
    destinationChainId: destinationChainId,
    sender: ethers.constants.AddressZero,
    receiver: ethers.constants.AddressZero,
    payload: ethers.utils.id("1122"),
  },
  {
    id: 2,
    sourceChainId: sourceChainId,
    destinationChainId: destinationChainId,
    sender: ethers.constants.AddressZero,
    receiver: ethers.constants.AddressZero,
    payload: ethers.utils.id("2233"),
  },
];

async function generateMsg() {
  const input = process.argv[2];
  const data = ethers.utils.defaultAbiCoder.decode(["bytes32"], input);
  domain = data[0];

  await mcl.init();

  accounts = await ethers.getSigners();
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

  eventRoot = ethers.utils.hexlify(ethers.utils.randomBytes(32));
  blockHash = ethers.utils.hexlify(ethers.utils.randomBytes(32));
  currentValidatorSetHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]"],
      [validatorSet]
    )
  );

  generateSignature0();
  generateSignature1();
  generateSignature2();
  generateSignature3();

  const output = ethers.utils.defaultAbiCoder.encode(
    [
      "tuple(address _address, uint256[4] blsKey, uint256 votingPower)[]",
      "uint256[2][]",
      "bytes[]",
      "tuple(uint256 id, uint256 sourceChainId, uint256 destinationChainId, address sender, address receiver, bytes payload)[]",
    ],
    [validatorSet, aggMessagePoints, bitmaps, msgs]
  );

  console.log(output);
}

function generateSignature0() {
  const bitmapStr = "ffff";

  const bitmap = `0x${bitmapStr}`;
  const message = "0x1234";

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature1() {
  const bitmapStr = "00";

  const bitmap = `0x${bitmapStr}`;

  const encodedMessage1 = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "uint256", "uint256", "address", "address", "bytes"],
    [msgs[0].id, msgs[0].sourceChainId, msgs[0].destinationChainId, msgs[0].sender, msgs[0].receiver, msgs[0].payload]
  );
  const hash1 = ethers.utils.keccak256(encodedMessage1);

  const encodedMessage2 = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "uint256", "uint256", "address", "address", "bytes"],
    [msgs[1].id, msgs[1].sourceChainId, msgs[1].destinationChainId, msgs[1].sender, msgs[1].receiver, msgs[1].payload]
  );
  const hash2 = ethers.utils.keccak256(encodedMessage2);

  const concatenatedHashes = ethers.utils.hexConcat([hash1, hash2]);
  const root = ethers.utils.keccak256(concatenatedHashes);

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(["bytes32", "uint256", "uint256", "uint256", "uint256"], [root, 1, 2, 2, 3])
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature2() {
  const bitmapStr = "01";

  const bitmap = `0x${bitmapStr}`;

  const encodedMessage1 = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "uint256", "uint256", "address", "address", "bytes"],
    [msgs[0].id, msgs[0].sourceChainId, msgs[0].destinationChainId, msgs[0].sender, msgs[0].receiver, msgs[0].payload]
  );
  const hash1 = ethers.utils.keccak256(encodedMessage1);

  const encodedMessage2 = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "uint256", "uint256", "address", "address", "bytes"],
    [msgs[1].id, msgs[1].sourceChainId, msgs[1].destinationChainId, msgs[1].sender, msgs[1].receiver, msgs[1].payload]
  );
  const hash2 = ethers.utils.keccak256(encodedMessage2);

  const concatenatedHashes = ethers.utils.hexConcat([hash1, hash2]);
  const root = ethers.utils.keccak256(concatenatedHashes);

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(["bytes32", "uint256", "uint256", "uint256", "uint256"], [root, 1, 2, 2, 3])
  );
  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

function generateSignature3() {
  const bitmapStr = "ffff";

  const bitmap = `0x${bitmapStr}`;

  const encodedMessage1 = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "uint256", "uint256", "address", "address", "bytes"],
    [msgs[0].id, msgs[0].sourceChainId, msgs[0].destinationChainId, msgs[0].sender, msgs[0].receiver, msgs[0].payload]
  );
  const hash1 = ethers.utils.keccak256(encodedMessage1);

  const encodedMessage2 = ethers.utils.defaultAbiCoder.encode(
    ["uint256", "uint256", "uint256", "address", "address", "bytes"],
    [msgs[1].id, msgs[1].sourceChainId, msgs[1].destinationChainId, msgs[1].sender, msgs[1].receiver, msgs[1].payload]
  );
  const hash2 = ethers.utils.keccak256(encodedMessage2);

  const concatenatedHashes = ethers.utils.hexConcat([hash1, hash2]);
  const root = ethers.utils.keccak256(concatenatedHashes);

  const message = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(["bytes32", "uint256", "uint256", "uint256", "uint256"], [root, 1, 2, 2, 3])
  );

  const signatures: mcl.Signature[] = [];
  let flag = false;

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
      const { signature, messagePoint } = mcl.sign(message, validatorSecretKeys[i], ethers.utils.arrayify(domain));
      signatures.push(signature);
      aggVotingPower = validatorSet[i].votingPower.add(aggVotingPower);
    } else {
      continue;
    }
  }

  const aggMessagePoint: mcl.MessagePoint = mcl.g1ToHex(mcl.aggregateRaw(signatures));
  aggMessagePoints.push(aggMessagePoint);
  bitmaps.push(bitmap);
  aggVotingPowers.push(aggVotingPower);
}

generateMsg();
