// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract MinFeeUSDFor_Integration_Test is Integration_Test {
    function test_GivenCustomFeeUSDNotSet() external view {
        // It should return min fee USD.
        assertEq(factoryMerkleBase.minFeeUSDFor(users.campaignCreator), MIN_FEE_USD, "minFeeUSDFor");
    }

    function test_GivenCustomFeeUSDSet() external {
        // Set a custom fee USD.
        resetPrank({ msgSender: users.admin });
        factoryMerkleBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0 });

        // It should return the custom fee USD.
        assertEq(factoryMerkleBase.minFeeUSDFor(users.campaignCreator), 0, "minFeeUSDFor");
    }
}
