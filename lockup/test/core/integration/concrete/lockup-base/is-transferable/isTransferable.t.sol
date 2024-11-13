// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract IsTransferable_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));
        lockup.isTransferable(nullStreamId);
    }

    function test_GivenNonTransferableStream() external view givenNotNull {
        bool isTransferable = lockup.isTransferable(notTransferableStreamId);
        assertFalse(isTransferable, "isTransferable");
    }

    function test_GivenTransferableStream() external view givenNotNull {
        bool isTransferable = lockup.isTransferable(defaultStreamId);
        assertTrue(isTransferable, "isTransferable");
    }
}
