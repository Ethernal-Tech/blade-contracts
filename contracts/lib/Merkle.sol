// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Merkle tree Lib
 * @notice merkle tree helper functions
 */
library Merkle {
    /**
     * @notice helper function to compute the Merkle Root from an array of already hashed leaves
     * @param leaves hashed leaves of the merkle tree
     */
    function computeMerkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        if (leaves.length == 1) {
            return leaves[0]; // If there's only one leaf, it is the root
        }

        // Continue hashing pairs of nodes until the root is obtained
        while (leaves.length > 1) {
            uint256 nextLevelSize = (leaves.length + 1) / 2;
            bytes32[] memory nextLevel = new bytes32[](nextLevelSize);

            uint256 j = 0;
            for (uint256 i = 0; i < leaves.length; i += 2) {
                bytes32 left = leaves[i];
                bytes32 right = i + 1 < leaves.length ? leaves[i + 1] : left;
                nextLevel[j] = keccak256(abi.encode(left, right));
                j++;
            }

            leaves = nextLevel;
        }

        return leaves[0];
    }
}
