// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { SablierV2OpenEnded } from "src/SablierV2OpenEnded.sol";
import { Integration_Test } from "./Integration.t.sol";

contract Constructor_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        // Construct the contract.
        SablierV2OpenEnded constructedOpenEnded = new SablierV2OpenEnded();

        uint256 actualStreamId = constructedOpenEnded.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");
    }
}
