// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { LockupTranched } from "src/core/types/DataTypes.sol";

import { LockupTranched_Integration_Shared_Test } from "../LockupTranched.t.sol";

contract GetStream_LockupTranched_Integration_Concrete_Test is LockupTranched_Integration_Shared_Test {
    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockupTranched.getStream(nullStreamId);
    }

    function test_GivenSettledStream() external givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // It should return the stream struct.
        LockupTranched.StreamLT memory actualStream = lockupTranched.getStream(defaultStreamId);
        LockupTranched.StreamLT memory expectedStream = defaults.lockupTranchedStream();
        // It should always return stream as non-cancelable.
        expectedStream.isCancelable = false;
        assertEq(actualStream, expectedStream);
    }

    function test_GivenNotSettledStream() external givenNotNull {
        uint256 streamId = createDefaultStream();
        // It should return the stream struct.
        LockupTranched.StreamLT memory actualStream = lockupTranched.getStream(streamId);
        LockupTranched.StreamLT memory expectedStream = defaults.lockupTranchedStream();
        assertEq(actualStream, expectedStream);
    }
}
