// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract CalculateMinFeeWei_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        // It should revert.
        expectRevert_Null(abi.encodeCall(bob.calculateMinFeeWei, (vaultIds.nullVault)));
    }

    function test_GivenAdapter() external view givenNotNull {
        // It should return zero.
        uint256 minFeeWei = bob.calculateMinFeeWei(vaultIds.vaultWithAdapter);
        uint256 expectedFeeWei = 0;
        assertEq(minFeeWei, expectedFeeWei, "vault did not return 0");
    }

    function test_GivenNoAdapter() external view givenNotNull {
        // It should return the minimum fee in wei.
        uint256 actualFeeWei = bob.calculateMinFeeWei(vaultIds.defaultVault);
        uint256 expectedFeeWei = BOB_MIN_FEE_WEI;
        assertEq(actualFeeWei, expectedFeeWei, "vault did not return the minimum fee in wei");
    }
}
