// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Base_Test } from "../Base.t.sol";

/// @title Fuzz_Test
/// @notice Base test contract with common logic needed by all fuzz test contracts.
abstract contract Fuzz_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the entire protocol.
        deployProtocol();

        // Make the admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });

        // Approve all protocol contracts to spend ERC-20 assets from the users.
        approveProtocol();
    }
}
