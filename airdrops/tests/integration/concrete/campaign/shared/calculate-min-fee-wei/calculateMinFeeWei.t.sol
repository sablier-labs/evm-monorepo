// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract CalculateMinFeeWei_Integration_Test is Integration_Test {
    function test_GivenFeeIsLowered() external {
        setMsgSender(address(comptroller));
        merkleBase.lowerMinFeeUSD(0);

        // It should return the new fee in wei.
        assertEq(merkleBase.calculateMinFeeWei(), 0);
    }

    function test_GivenFeeIsNotLowered() external view {
        // It should return the original fee in wei.
        assertEq(merkleBase.calculateMinFeeWei(), AIRDROP_MIN_FEE_WEI);
    }
}
