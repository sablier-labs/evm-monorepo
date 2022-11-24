// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";

import { BaseTest } from "../BaseTest.t.sol";

/// @title E2eTest
/// @notice Collections of tests run against a mainnet fork.
/// @dev Strictly for test purposes.
abstract contract E2eTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                       STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2Linear internal sablierV2Linear;
    SablierV2Pro internal sablierV2Pro;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));

        sablierV2Linear = new SablierV2Linear();
        sablierV2Pro = new SablierV2Pro(MAX_SEGMENT_COUNT);
    }
}
