// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/core/libraries/Errors.sol";
import { LockupLinear } from "src/core/types/DataTypes.sol";

import { LockupLinear_Integration_Shared_Test } from "../LockupLinear.t.sol";

contract GetTimestamps_LockupLinear_Integration_Concrete_Test is LockupLinear_Integration_Shared_Test {
    function test_RevertGiven_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockupLinear.getTimestamps(nullStreamId);
    }

    function test_GivenNotNull() external {
        uint256 streamId = createDefaultStream();
        LockupLinear.Timestamps memory actualTimestamps = lockupLinear.getTimestamps(streamId);
        LockupLinear.Timestamps memory expectedTimestamps = defaults.lockupLinearTimestamps();
        assertEq(actualTimestamps, expectedTimestamps);
    }
}
