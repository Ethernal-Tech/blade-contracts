// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {StdAssertions} from "forge-std/StdAssertions.sol";
import "contracts/lib/Merkle.sol";

contract TestMerkle is StdAssertions {
    using Merkle for bytes32[];

    function testComputeMerkleRootSingleLeaf() public {
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = keccak256(abi.encodePacked("leaf1"));

        bytes32 expectedRoot = leaves[0];
        bytes32 computedRoot = leaves.computeMerkleRoot();

        if (computedRoot != expectedRoot) {
            emit log("Error. Merkle root should be equal to the single leaf hash");
            fail();
        }
    }

    function testComputeMerkleRootTwoLeaves() public {
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encodePacked("leaf1"));
        leaves[1] = keccak256(abi.encodePacked("leaf2"));

        bytes32 expectedRoot = keccak256(abi.encodePacked(leaves[0], leaves[1]));
        bytes32 computedRoot = leaves.computeMerkleRoot();

        if (computedRoot != expectedRoot) {
            emit log("Error. Merkle root should be the hash of the two leaves");
            fail();
        }
    }

    function testComputeMerkleRootMultipleUnevenLeaves() public {
        bytes32[] memory leaves = new bytes32[](5);
        leaves[0] = 0x0dc750b2567268c0f72a3fca9d20e2dd91cacdd9fe31ab89871c91faab19ae64;
        leaves[1] = 0xa4d070b9479a372285b6979ef376b460ac6e53692d594352ea5fbd318de73a84;
        leaves[2] = 0xa3d4366ab0735ec2da9bc5edf7163f7409207bffbbe972091a3362c44c682575;
        leaves[3] = 0xe6f47c751ac937f8bd19749dc76250f0436b8f5f08bfb5b7dac5609eb4476556;
        leaves[4] = 0x406253fb3e886db7319faf5ebc8073816cdd871f774b3db76b6c02ea2a4dffcf;

        bytes32 expectedRoot = 0x72705157d25af8c3d331493ec077c181970b56e569829d3ccb88174d2ead54e8;
        bytes32 computedRoot = leaves.computeMerkleRoot();

        if (computedRoot != expectedRoot) {
            emit log("Error. Merkle root should be the hash of the combined hashes of the leaves");
            fail();
        }
    }

    function testComputeMerkleRootMultipleEvenLeaves() public {
        bytes32[] memory leaves = new bytes32[](6);
        leaves[0] = 0x0dc750b2567268c0f72a3fca9d20e2dd91cacdd9fe31ab89871c91faab19ae64;
        leaves[1] = 0xa4d070b9479a372285b6979ef376b460ac6e53692d594352ea5fbd318de73a84;
        leaves[2] = 0xa3d4366ab0735ec2da9bc5edf7163f7409207bffbbe972091a3362c44c682575;
        leaves[3] = 0xe6f47c751ac937f8bd19749dc76250f0436b8f5f08bfb5b7dac5609eb4476556;
        leaves[4] = 0x406253fb3e886db7319faf5ebc8073816cdd871f774b3db76b6c02ea2a4dffcf;
        leaves[5] = 0xf91e8f39b52534168cea2bd8f970b0311286cb8143da29983daf5c708e52878c;

        bytes32 expectedRoot = 0x2e5740d538ba02540af7c65fd5211bfbddab9fdbd20a34143d26925a6655db46;
        bytes32 computedRoot = leaves.computeMerkleRoot();

        if (computedRoot != expectedRoot) {
            emit log("Error. Merkle root should be the hash of the combined hashes of the leaves");
            fail();
        }
    }
}