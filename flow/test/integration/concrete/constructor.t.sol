// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { SablierFlow } from "src/SablierFlow.sol";

import { Integration_Test } from "../Integration.t.sol";

contract Constructor_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        // Construct the contract.
        SablierFlow constructedFlow = new SablierFlow(users.admin, nftDescriptor);

        // {SablierFlowState.MAX_BROKER_FEE}
        UD60x18 actualMaxBrokerFee = constructedFlow.MAX_BROKER_FEE();
        UD60x18 expectedMaxBrokerFee = UD60x18.wrap(0.1e18);
        assertEq(actualMaxBrokerFee, expectedMaxBrokerFee, "MAX_BROKER_FEE");

        // {SablierFlowState.nextStreamId}
        uint256 actualStreamId = constructedFlow.nextStreamId();
        uint256 expectedStreamId = 1;
        assertEq(actualStreamId, expectedStreamId, "nextStreamId");

        address actualAdmin = constructedFlow.admin();
        address expectedAdmin = users.admin;
        assertEq(actualAdmin, expectedAdmin, "admin");

        address actualNFTDescriptor = address(constructedFlow.nftDescriptor());
        address expectedNFTDescriptor = address(nftDescriptor);
        assertEq(actualNFTDescriptor, expectedNFTDescriptor, "nftDescriptor");
    }
}
