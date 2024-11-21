// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Batch_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallFunctionNotExist() external {
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeWithSignature("nonExistentFunction()");

        vm.expectRevert();
        lockup.batch(calls);
    }

    function test_RevertWhen_DataInvalid() external whenCallFunctionExists {
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(lockup.getDepositedAmount, (nullStreamId));

        bytes memory expectedRevertData = abi.encodeWithSelector(
            Errors.BatchError.selector, abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId)
        );

        vm.expectRevert(expectedRevertData);

        lockup.batch(calls);
    }

    function test_WhenDataValid() external whenCallFunctionExists {
        resetPrank({ msgSender: users.sender });

        assertFalse(lockup.wasCanceled(defaultStreamId));

        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeCall(lockup.cancel, (defaultStreamId));

        lockup.batch(calls);
        assertTrue(lockup.wasCanceled(defaultStreamId));
    }
}
