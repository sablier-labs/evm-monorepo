// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { SablierV2OpenEnded } from "src/SablierV2OpenEnded.sol";

import { Integration_Test } from "./Integration.t.sol";

contract Constructor_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        // Construct the contract.
        SablierV2OpenEnded constructedOpenEnded = new SablierV2OpenEnded();

        // {SablierV2OpenEndedState.MAX_BROKER_FEE}
        UD60x18 actualMaxBrokerFee = constructedOpenEnded.MAX_BROKER_FEE();
        UD60x18 expectedMaxBrokerFee = UD60x18.wrap(0.1e18);
        assertEq(actualMaxBrokerFee, expectedMaxBrokerFee, "MAX_BROKER_FEE");

        // {SablierV2OpenEndedState.nextStreamId}
        uint256 actualStreamId = constructedOpenEnded.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");
    }
}
