// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsAllowedToHook_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    function test_GivenProvidedAddressNotAllowedToHook() external view {
        bool result = lockup.isAllowedToHook(address(recipientGood));
        assertFalse(result, "isAllowedToHook");
    }

    function test_GivenProvidedAddressAllowedToHook() external {
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientGood));

        bool result = lockup.isAllowedToHook(address(recipientGood));
        assertTrue(result, "isAllowedToHook");
    }
}
