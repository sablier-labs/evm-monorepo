// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable reason-string
pragma solidity >=0.8.22;

import { LibSort } from "solady/src/utils/LibSort.sol";

/// @dev Encapsulates the data needed to compute a Merkle tree leaf.
struct LeafData {
    uint256 index;
    address recipient;
    uint128 amount;
}

/// @dev A helper library for building Merkle leaves, roots, and proofs.
library MerkleBuilder {
    /// @dev Double hashes the data needed for a Merkle tree leaf.
    function computeLeaf(LeafData memory leafData) internal pure returns (uint256 leaf) {
        leaf =
            uint256(keccak256(bytes.concat(keccak256(abi.encode(leafData.index, leafData.recipient, leafData.amount)))));
    }

    /// @dev Compute leaves for given data and sort them in ascending order.
    function computeLeaves(uint256[] storage leaves, LeafData[] memory leafData) internal {
        for (uint256 i = 0; i < leafData.length; ++i) {
            leaves.push(computeLeaf(leafData[i]));
        }

        // Sort the leaves in ascending order to match the production environment.
        sort(leaves);
    }

    /// @dev Convert a storage array to memory and sorts it in ascending order. We need this because `LibSort` does not
    /// support storage arrays.
    function sort(uint256[] storage leaves) internal {
        uint256 leavesCount = leaves.length;

        // Declare the memory array.
        uint256[] memory _leaves = new uint256[](leavesCount);
        for (uint256 i = 0; i < leavesCount; ++i) {
            _leaves[i] = leaves[i];
        }

        // Sort the memory array.
        LibSort.sort(_leaves);

        // Copy the memory array back to storage.
        for (uint256 i = 0; i < leavesCount; ++i) {
            leaves[i] = _leaves[i];
        }
    }

    /// @dev Converts an array of `uint256` to an array of `bytes32`.
    function toBytes32(uint256[] storage arr_) internal view returns (bytes32[] memory arr) {
        arr = new bytes32[](arr_.length);
        for (uint256 i = 0; i < arr_.length; ++i) {
            arr[i] = bytes32(arr_[i]);
        }
    }
}
