// SPDX-License-Identifier: GPL-3-0-or-later
pragma solidity >=0.8.22;

import { ISablierMerkleInstant } from "@sablier/airdrops/src/interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "@sablier/airdrops/src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "@sablier/airdrops/src/interfaces/ISablierMerkleLT.sol";
import { Test } from "forge-std/src/Test.sol";

import { MerkleCreator } from "./MerkleCreator.sol";

contract MerkleCreatorTest is Test {
    // Test contract
    MerkleCreator internal merkleCreator;

    address internal user;

    function setUp() public {
        // Fork Ethereum Mainnet
        vm.createSelectFork("mainnet");

        // Deploy the Merkle creator
        merkleCreator = new MerkleCreator();

        // Create a test user
        user = payable(makeAddr("User"));
        vm.deal({ account: user, newBalance: 1 ether });

        // Make the test user the `msg.sender` in all following calls
        vm.startPrank({ msgSender: user });
    }

    // Test creating the MerkleInstant campaign.
    function test_CreateMerkleInstant() public {
        ISablierMerkleInstant merkleInstant = merkleCreator.createMerkleInstant();

        // Assert the merkleLL contract was created with correct params
        assertEq(address(0xBeeF), merkleInstant.admin(), "admin");
        assertEq(
            0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123,
            merkleInstant.MERKLE_ROOT(),
            "merkle-root"
        );
    }

    // Test creating the MerkleLL campaign.
    function test_CreateMerkleLL() public {
        ISablierMerkleLL merkleLL = merkleCreator.createMerkleLL();

        // Assert the merkleLL contract was created with correct params
        assertEq(address(0xBeeF), merkleLL.admin(), "admin");
        assertEq(
            0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123, merkleLL.MERKLE_ROOT(), "merkle-root"
        );
    }

    // Test creating the MerkleLT campaign.
    function test_CreateMerkleLT() public {
        ISablierMerkleLT merkleLT = merkleCreator.createMerkleLT();

        // Assert the merkleLT contract was created with correct params
        assertEq(address(0xBeeF), merkleLT.admin(), "admin");
        assertEq(
            0x4e07408562bedb8b60ce05c1decfe3ad16b722309875f562c03d02d7aaacb123, merkleLT.MERKLE_ROOT(), "merkle-root"
        );
    }
}
