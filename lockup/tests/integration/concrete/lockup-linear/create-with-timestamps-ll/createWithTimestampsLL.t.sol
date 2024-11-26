// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import {
    CreateWithTimestamps_Integration_Concrete_Test,
    Integration_Test
} from "../../lockup-base/create-with-timestamps/createWithTimestamps.t.sol";

contract CreateWithTimestampsLL_Integration_Concrete_Test is CreateWithTimestamps_Integration_Concrete_Test {
    function setUp() public override {
        Integration_Test.setUp();
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
    }

    function test_RevertWhen_CliffUnlockAmountNotZero()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
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
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
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
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenContract
        whenCliffTimeZero
    {
        uint40 cliffTime = 0;
        _testCreateWithTimestampsLL(address(dai), cliffTime);
    }

    function test_RevertWhen_StartTimeNotLessThanCliffTime()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
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
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
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
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
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
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
        whenUnlockAmountsSumNotExceedDepositAmount
    {
        _testCreateWithTimestampsLL(address(usdt), _defaultParams.cliffTime);
    }

    function test_WhenTokenNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenContract
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
        whenUnlockAmountsSumNotExceedDepositAmount
    {
        _testCreateWithTimestampsLL(address(dai), _defaultParams.cliffTime);
    }

    /// @dev Shared logic between {test_WhenStartTimeLessThanEndTime}, {test_WhenTokenMissesERC20ReturnValue} and
    /// {test_WhenTokenNotMissERC20ReturnValue}.
    function _testCreateWithTimestampsLL(address token, uint40 cliffTime) private {
        // Make the Sender the stream's funder.
        address funder = users.sender;
        uint256 expectedStreamId = lockup.nextStreamId();

        // Set the default parameters.
        _defaultParams.createWithTimestamps.token = IERC20(token);
        _defaultParams.unlockAmounts.cliff = cliffTime == 0 ? 0 : _defaultParams.unlockAmounts.cliff;
        _defaultParams.cliffTime = cliffTime;

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            token: IERC20(token),
            from: funder,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({
            token: IERC20(token),
            from: funder,
            to: users.broker,
            value: defaults.BROKER_FEE_AMOUNT()
        });

        // It should emit {MetadataUpdate} and {CreateLockupLinearStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(IERC20(token)),
            cliffTime: cliffTime,
            unlockAmounts: _defaultParams.unlockAmounts
        });

        // Create the stream.
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId);
        assertEq(lockup.getCliffTime(streamId), cliffTime, "cliffTime");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_LINEAR);
        assertEq(lockup.getUnderlyingToken(streamId), IERC20(token), "underlyingToken");
        assertEq(lockup.getUnlockAmounts(streamId).start, _defaultParams.unlockAmounts.start, "unlockAmounts.start");
        assertEq(lockup.getUnlockAmounts(streamId).cliff, _defaultParams.unlockAmounts.cliff, "unlockAmounts.cliff");
    }
}
