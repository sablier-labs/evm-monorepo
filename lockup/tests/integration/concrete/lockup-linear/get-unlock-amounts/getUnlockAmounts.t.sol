// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Lockup_Linear_Integration_Concrete_Test } from "../LockupLinear.t.sol";

contract GetUnlockAmounts_Integration_Concrete_Test is Lockup_Linear_Integration_Concrete_Test {
    function test_RevertGiven_Null() external {
        expectRevert_Null({ callData: abi.encodeCall(lockup.getUnlockAmounts, nullStreamId) });
    }

    function test_RevertGiven_NotLinearModel() external givenNotNull {
        lockupModel = Lockup.Model.LOCKUP_TRANCHED;
        uint256 streamId = createDefaultStream();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_NotExpectedModel.selector, Lockup.Model.LOCKUP_TRANCHED, Lockup.Model.LOCKUP_LINEAR
            )
        );
        lockup.getUnlockAmounts(streamId);
    }

    function test_GivenBothAmountsZero() external givenNotNull givenLinearModel {
        _defaultParams.unlockAmounts = defaults.unlockAmountsZero();
        uint256 streamId = createDefaultStream();
        LockupLinear.UnlockAmounts memory unlockAmounts = lockup.getUnlockAmounts(streamId);
        assertEq(unlockAmounts.start, 0, "unlockAmounts.start");
        assertEq(unlockAmounts.cliff, 0, "unlockAmounts.cliff");
    }

    function test_GivenStartUnlockAmountZero() external view givenNotNull givenLinearModel givenOnlyOneAmountZero {
        LockupLinear.UnlockAmounts memory unlockAmounts = lockup.getUnlockAmounts(defaultStreamId);
        assertEq(unlockAmounts.start, 0, "unlockAmounts.start");
        assertEq(unlockAmounts.cliff, defaults.CLIFF_AMOUNT(), "unlockAmounts.cliff");
    }

    function test_GivenStartUnlockAmountNotZero() external givenNotNull givenLinearModel givenOnlyOneAmountZero {
        _defaultParams.unlockAmounts.start = 1;
        _defaultParams.unlockAmounts.cliff = 0;
        uint256 streamId = createDefaultStream();
        LockupLinear.UnlockAmounts memory unlockAmounts = lockup.getUnlockAmounts(streamId);
        assertEq(unlockAmounts.start, 1, "unlockAmounts.start");
        assertEq(unlockAmounts.cliff, 0, "unlockAmounts.cliff");
    }

    function test_GivenBothAmountsNotZero() external givenNotNull givenLinearModel {
        _defaultParams.unlockAmounts.start = 1;
        uint256 streamId = createDefaultStream();
        LockupLinear.UnlockAmounts memory unlockAmounts = lockup.getUnlockAmounts(streamId);
        assertEq(unlockAmounts.start, 1, "unlockAmounts.start");
        assertEq(unlockAmounts.cliff, defaults.CLIFF_AMOUNT(), "unlockAmounts.cliff");
    }
}
