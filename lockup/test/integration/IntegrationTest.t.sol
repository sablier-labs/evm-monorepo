// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { BaseTest } from "../BaseTest.t.sol";

/// @title IntegrationTest
/// @notice Collections of tests run against a mainnet fork.
abstract contract IntegrationTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.1e18);
    uint256 internal constant MAX_SEGMENT_COUNT = 200;

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2Linear internal sablierV2Linear;
    SablierV2Pro internal sablierV2Pro;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.createSelectFork({ urlOrAlias: vm.envString("ETH_RPC_URL"), blockNumber: 16_126_000 });

        vm.startPrank(users.owner);
        sablierV2Linear = new SablierV2Linear({ maxGlobalFee: MAX_GLOBAL_FEE });
        sablierV2Pro = new SablierV2Pro({ maxGlobalFee: MAX_GLOBAL_FEE, maxSegmentCount: MAX_SEGMENT_COUNT });
    }
}
