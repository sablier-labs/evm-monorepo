// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract ProtocolFees_Unit_Test is Comptroller_Unit_Test {
    function setUp() public override {
        Comptroller_Unit_Test.setUp();

        // Make the admin the caller in this test suite.
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
