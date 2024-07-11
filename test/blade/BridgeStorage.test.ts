import { expect } from "chai";
import { BigNumber } from "ethers";
import * as hre from "hardhat";
import { ethers } from "hardhat";
import { MerkleTree } from "merkletreejs";
import { BridgeStorage} from "../../typechain-types";
import { alwaysFalseBytecode, alwaysRevertBytecode, alwaysTrueBytecode } from "../constants";
import { HashZero } from "./accountAbstraction/testutils";

describe("BridgeStorage", () => {
  let bridgeStorage: BridgeStorage,
    msgs: any[];
  before(async () => {
    const BridgeStorage = await ethers.getContractFactory("BridgeStorage");
    bridgeStorage = (await BridgeStorage.deploy()) as BridgeStorage;

    await bridgeStorage.deployed();
  });

  it("State sync commit fail: no system call", async () => {
    const commitment = {
      startId: 1,
      endId: 1,
      root: ethers.constants.HashZero,
    };

    msgs = [];

    msgs = [{
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
    }
    ]

    let sign: [number,number]

    sign = [1,1]


    const batch = {
        messages: msgs, 
        signature:sign,
        bitmap: ethers.constants.AddressZero

    }

    const firstTx = await bridgeStorage.commitBatch(batch);
    const firstReceipt = await firstTx.wait()
    const firstLogs = firstReceipt?.events?.filter((log) => log.event === "NewBatch") as any[];
    expect(firstLogs).to.exist;
    expect(firstLogs[0]?.args?.id).to.equal(0)

    const secondTx = await bridgeStorage.commitBatch(batch);
    const secondReceipt = await secondTx.wait()
    const secondLogs = secondReceipt?.events?.filter((log) => log.event === "NewBatch") as any[];
    expect(secondLogs).to.exist;
    expect(secondLogs[0]?.args?.id).to.equal(1);
    });
});
