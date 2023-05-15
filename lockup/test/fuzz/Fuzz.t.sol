// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Base_Test } from "../Base.t.sol";

/// @title Fuzz_Test
/// @notice Common logic needed by all fuzz tests.
abstract contract Fuzz_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy V2 Core.
        deployProtocolConditionally();

        // Make the admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });

        // Approve V2 Core to spend assets from the users.
        approveProtocol();
    }
}
