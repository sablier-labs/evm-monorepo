// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";
import { CommonBase } from "../Base.sol";

abstract contract Unit_Test is CommonBase, StdAssertions {
    address internal admin;
    address internal alice;
    address internal eve;

    function setUp() public virtual override {
        CommonBase.setUp();

        address[] memory noSpenders = new address[](0);

        admin = createUser("admin", noSpenders);
        alice = createUser("alice", noSpenders);
        eve = createUser("eve", noSpenders);

        resetPrank(admin);
    }
}
