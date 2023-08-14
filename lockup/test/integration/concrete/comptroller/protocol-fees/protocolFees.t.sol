// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract ProtocolFees_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Make the Admin the caller in this test suite.
        changePrank({ msgSender: users.admin });
    }

    function test_ProtocolFees_ProtocolFeeNotSet() external {
        UD60x18 actualProtocolFee = comptroller.protocolFees(dai);
        UD60x18 expectedProtocolFee = ZERO;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFees");
    }

    modifier whenProtocolFeeSet() {
        comptroller.setProtocolFee({ asset: dai, newProtocolFee: defaults.PROTOCOL_FEE() });
        _;
    }

    function test_ProtocolFees() external whenProtocolFeeSet {
        UD60x18 actualProtocolFee = comptroller.protocolFees(dai);
        UD60x18 expectedProtocolFee = defaults.PROTOCOL_FEE();
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFees");
    }
}
