// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockupLinear } from "src/interfaces/ISablierLockupLinear.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";

import {
    CreateWithTimestamps_Integration_Concrete_Test,
    Integration_Test
} from "../../lockup/create-with-timestamps/createWithTimestamps.t.sol";

contract CreateWithTimestampsLL_Integration_Concrete_Test is CreateWithTimestamps_Integration_Concrete_Test {
    function setUp() public override {
        Integration_Test.setUp();
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
    }

    function test_RevertWhen_CliffUnlockAmountNotZero()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeZero
    {
        _defaultParams.cliffTime = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_CliffTimeZeroUnlockAmountNotZero.selector, _defaultParams.unlockAmounts.cliff
            )
        );
        createDefaultStream();
    }

    function test_RevertWhen_StartTimeNotLessThanEndTime()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeZero
    {
        uint40 startTime = defaults.END_TIME();
        uint40 endTime = defaults.START_TIME();
        _defaultParams.createWithTimestamps.timestamps.start = startTime;
        _defaultParams.createWithTimestamps.timestamps.end = endTime;
        _defaultParams.cliffTime = 0;
        _defaultParams.unlockAmounts.cliff = 0;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_StartTimeNotLessThanEndTime.selector, startTime, endTime)
        );
        createDefaultStream();
    }

    function test_WhenStartTimeLessThanEndTime()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeZero
    {
        uint40 cliffTime = 0;
        _testCreateWithTimestampsLL(cliffTime);
    }

    function test_RevertWhen_StartTimeNotLessThanCliffTime()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeNotZero
    {
        uint40 startTime = defaults.CLIFF_TIME();
        uint40 endTime = defaults.END_TIME();
        uint40 cliffTime = defaults.START_TIME();

        _defaultParams.createWithTimestamps.timestamps.start = startTime;
        _defaultParams.createWithTimestamps.timestamps.end = endTime;
        _defaultParams.cliffTime = cliffTime;

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierHelpers_StartTimeNotLessThanCliffTime.selector, startTime, cliffTime)
        );
        createDefaultStream();
    }

    function test_RevertWhen_CliffTimeNotLessThanEndTime()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
    {
        _defaultParams.cliffTime = defaults.END_TIME() + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_CliffTimeNotLessThanEndTime.selector,
                _defaultParams.cliffTime,
                _defaultParams.createWithTimestamps.timestamps.end
            )
        );
        createDefaultStream();
    }

    function test_RevertWhen_UnlockAmountsSumExceedsDepositAmount()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
    {
        uint128 depositAmount = defaults.DEPOSIT_AMOUNT();
        _defaultParams.unlockAmounts.start = depositAmount;
        _defaultParams.unlockAmounts.cliff = 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_UnlockAmountsSumTooHigh.selector, depositAmount, depositAmount, 1
            )
        );
        createDefaultStream();
    }

    function test_WhenTokenMissesERC20ReturnValue()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
        whenUnlockAmountsSumNotExceedDepositAmount
    {
        IERC20 _usdt = IERC20(address(usdt));

        // Update the default parameters.
        _defaultParams.createWithTimestamps.token = _usdt;
        _defaultParams.createWithTimestamps.depositAmount = defaults.DEPOSIT_AMOUNT_6D();
        _defaultParams.unlockAmounts.cliff = defaults.CLIFF_AMOUNT_6D();

        uint256 previousAggregateAmount = lockup.aggregateAmount(_usdt);
        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            token: _usdt,
            from: users.sender,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT_6D()
        });

        // It should emit {MetadataUpdate} and {CreateLockupLinearStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupLinear.CreateLockupLinearStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(_usdt, defaults.DEPOSIT_AMOUNT_6D()),
            cliffTime: _defaultParams.cliffTime,
            unlockAmounts: _defaultParams.unlockAmounts
        });

        // Create the stream.
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId, _usdt);
        assertEq(lockup.getCliffTime(streamId), _defaultParams.cliffTime, "cliffTime");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_LINEAR);
        assertEq(lockup.getUnlockAmounts(streamId), _defaultParams.unlockAmounts);
        assertEq(
            lockup.aggregateAmount(_usdt), previousAggregateAmount + defaults.DEPOSIT_AMOUNT_6D(), "aggregateAmount"
        );
    }

    function test_WhenTokenNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
        whenUnlockAmountsSumNotExceedDepositAmount
    {
        _testCreateWithTimestampsLL(_defaultParams.cliffTime);
    }

    /// @dev Shared logic between {test_WhenStartTimeLessThanEndTime} and {test_WhenTokenMissesERC20ReturnValue}.
    function _testCreateWithTimestampsLL(uint40 cliffTime) private {
        // Update the default parameters.
        _defaultParams.unlockAmounts.cliff = cliffTime == 0 ? 0 : _defaultParams.unlockAmounts.cliff;
        _defaultParams.cliffTime = cliffTime;

        uint256 previousAggregateAmount = lockup.aggregateAmount(dai);
        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            token: dai,
            from: users.sender,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // It should emit {MetadataUpdate} and {CreateLockupLinearStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupLinear.CreateLockupLinearStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(dai, defaults.DEPOSIT_AMOUNT()),
            cliffTime: cliffTime,
            unlockAmounts: _defaultParams.unlockAmounts
        });

        // Create the stream.
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId, dai);
        assertEq(lockup.getCliffTime(streamId), cliffTime, "cliffTime");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_LINEAR);
        assertEq(lockup.getUnlockAmounts(streamId), _defaultParams.unlockAmounts);
        assertEq(lockup.aggregateAmount(dai), previousAggregateAmount + defaults.DEPOSIT_AMOUNT(), "aggregateAmount");
    }
}
