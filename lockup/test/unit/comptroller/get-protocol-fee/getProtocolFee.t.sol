// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IOwnable } from "@prb/contracts/access/IOwnable.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2ComptrollerTest } from "../SablierV2Comptroller.t.sol";

contract GetProtocolFee__Test is SablierV2ComptrollerTest {
    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Make the owner the caller in this test suite.
        changePrank(users.owner);
    }

    /// @dev it should return zero.
    function testGetProtocolFee__ProtocolFeeNotSet() external {
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(address(dai));
        UD60x18 expectedProtocolFee = ZERO;
        assertEq(actualProtocolFee, expectedProtocolFee);
    }

    modifier ProtocolFeeSet() {
        comptroller.setProtocolFee(address(dai), DEFAULT_PROTOCOL_FEE);
        _;
    }

    /// @dev it should return the correct protocol fee.
    function testGetProtocolFee() external ProtocolFeeSet {
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(address(dai));
        UD60x18 expectedProtocolFee = DEFAULT_PROTOCOL_FEE;
        assertEq(actualProtocolFee, expectedProtocolFee);
    }
}
