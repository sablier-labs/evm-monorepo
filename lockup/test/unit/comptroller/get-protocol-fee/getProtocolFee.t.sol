// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract GetProtocolFee_Unit_Test is Comptroller_Unit_Test {
    function setUp() public override {
        Comptroller_Unit_Test.setUp();

        // Make the admin the caller in this test suite.
        changePrank({ msgSender: users.admin });
    }

    /// @dev it should return zero.
    function test_GetProtocolFee_ProtocolFeeNotSet() external {
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(DEFAULT_ASSET);
        UD60x18 expectedProtocolFee = ZERO;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }

    modifier protocolFeeSet() {
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: DEFAULT_PROTOCOL_FEE });
        _;
    }

    /// @dev it should return the correct protocol fee.
    function test_GetProtocolFee() external protocolFeeSet {
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(DEFAULT_ASSET);
        UD60x18 expectedProtocolFee = DEFAULT_PROTOCOL_FEE;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }
}
