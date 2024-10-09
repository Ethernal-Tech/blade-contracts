// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Merkle {
    // Helper function to compute the Merkle Root from an array of already hashed leaves
    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        if (leaves.length == 1) {
            return leaves[0]; // If there's only one leaf, it is the root
        }

        // Continue hashing pairs of nodes until the root is obtained
        while (leaves.length > 1) {
            uint256 nextLevelSize = (leaves.length + 1) / 2;
            bytes32[] memory nextLevel = new bytes32[](nextLevelSize);

            for (uint256 i = 0; i < leaves.length / 2; i++) {
                nextLevel[i] = keccak256(abi.encodePacked(leaves[2 * i], leaves[2 * i + 1]));
            }

            // If the number of leaves is odd, carry forward the last leaf
            if (leaves.length % 2 == 1) {
                nextLevel[nextLevel.length - 1] = leaves[leaves.length - 1];
            }

            leaves = nextLevel;
        }

        return leaves[0];
    }
}