// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract GetSender_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.getSender(nullStreamId);
    }

    function test_GivenNotNull() external view {
        address actualSender = lockup.getSender(defaultStreamId);
        address expectedSender = users.sender;
        assertEq(actualSender, expectedSender, "sender");
    }
}
