// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";
import { LibSort } from "solady/src/utils/LibSort.sol";

import { LeafData, MerkleBuilder } from "./MerkleBuilder.sol";

contract MerkleBuilder_Test is StdAssertions, StdUtils {
    function testFuzz_ComputeLeaf(uint256 index, address recipient, uint128 amount) external pure {
        uint256 actualLeaf = MerkleBuilder.computeLeaf(LeafData({ index: index, recipient: recipient, amount: amount }));
        uint256 expectedLeaf = uint256(keccak256(bytes.concat(keccak256(abi.encode(index, recipient, amount)))));
        assertEq(actualLeaf, expectedLeaf, "computeLeaf");
    }

    // MerkleBuilder.computeLeaves accepts as param a storage variable.
    uint256[] internal actualLeaves;

    function testFuzz_ComputeLeaves(LeafData[] memory params) external {
        MerkleBuilder.computeLeaves(actualLeaves, params);

        uint256[] memory expectedLeaves = new uint256[](params.length);
        for (uint256 i = 0; i < params.length; ++i) {
            expectedLeaves[i] = uint256(
                keccak256(bytes.concat(keccak256(abi.encode(params[i].index, params[i].recipient, params[i].amount))))
            );
        }
        LibSort.sort(expectedLeaves);

        assertEq(actualLeaves, expectedLeaves, "computeLeaves");
    }
}
