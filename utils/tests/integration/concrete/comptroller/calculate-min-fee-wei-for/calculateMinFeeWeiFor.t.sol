// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ConvertUSDFeeToWei_Comptroller_Concrete_Test } from "../convert-usd-fee-to-wei/convertUSDFeeToWei.t.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

/// @dev It inherits from {ConvertUSDFeeToWei_Comptroller_Concrete_Test} to avoid duplicating the common tests.
contract CalculateMinFeeWeiFor_Comptroller_Concrete_Test is ConvertUSDFeeToWei_Comptroller_Concrete_Test {
    function test_GivenCustomFeeNotSet(uint8 protocolIndex, address user) external view {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // It should return the min fee in wei.
        uint256 actualFeeInWei = comptroller.calculateMinFeeWeiFor(protocol, user);
        uint256 expectedFeeInWei = getFeeInWei(protocol);
        assertEq(actualFeeInWei, expectedFeeInWei, "custom fee not set");
    }

    function test_GivenCustomFeeSet(uint8 protocolIndex, address user, uint128 feeUSD) external {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Set the custom fee.
        feeUSD = boundUint128(feeUSD, 0, uint128(MAX_FEE_USD));
        comptroller.setCustomFeeUSDFor(protocol, user, feeUSD);

        // It should return the custom fee in wei.
        uint256 actualFeeInWei = comptroller.calculateMinFeeWeiFor(protocol, user);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "given custom fee set");
    }
}
