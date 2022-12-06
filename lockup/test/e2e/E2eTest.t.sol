// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { BaseTest } from "../BaseTest.t.sol";

/// @title E2eTest
/// @notice Collections of tests run against a mainnet fork.
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
        vm.createSelectFork({ endpoint: vm.envString("ETH_RPC_URL") });

        sablierV2Linear = new SablierV2Linear();
        sablierV2Pro = new SablierV2Pro({ maxSegmentCount: MAX_SEGMENT_COUNT });
    }
}
