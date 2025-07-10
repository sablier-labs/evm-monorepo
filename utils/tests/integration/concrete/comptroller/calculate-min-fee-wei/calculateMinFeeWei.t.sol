// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ConvertUSDFeeToWei_Comptroller_Concrete_Test } from "../convert-usd-fee-to-wei/convertUSDFeeToWei.t.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

/// @dev It inherits from {ConvertUSDFeeToWei_Comptroller_Concrete_Test} to avoid duplicating the common tests.
contract CalculateMinFeeWei_Comptroller_Concrete_Test is ConvertUSDFeeToWei_Comptroller_Concrete_Test {
    function test_GivenMinFeeNotSet(uint8 protocolIndex) external {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Set the min fee to zero.
        comptroller.setMinFeeUSD(protocol, 0);

        // It should return zero.
        assertEq(comptroller.calculateMinFeeWei(protocol), 0, "given min fee not set");
    }

    function test_GivenMinFeeSet(uint8 protocolIndex) external view {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        uint256 actualFeeInWei = comptroller.calculateMinFeeWei(protocol);
        uint256 expectedFeeInWei = getFeeInWei(protocol);

        // It should return the min fee in wei.
        assertEq(actualFeeInWei, expectedFeeInWei, "given min fee set");
    }
}
