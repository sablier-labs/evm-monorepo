// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";

contract GetFee_Integration_Test is Integration_Test {
    function test_GivenCustomFeeNotSet() external view {
        // It should return minimum fee.
        assertEq(merkleFactory.getFee(users.campaignOwner), defaults.MINIMUM_FEE(), "minimum fee");
    }

    function test_GivenCustomFeeSet() external {
        // Set the custom fee.
        resetPrank({ msgSender: users.admin });
        merkleFactory.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0 });

        // It should return custom fee.
        assertEq(merkleFactory.getFee(users.campaignOwner), 0, "custom fee");
    }
}
