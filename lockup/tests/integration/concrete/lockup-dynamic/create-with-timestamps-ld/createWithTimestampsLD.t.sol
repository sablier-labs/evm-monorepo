// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { stdError } from "forge-std/src/StdError.sol";
import { ISablierLockupDynamic } from "src/interfaces/ISablierLockupDynamic.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupDynamic } from "src/types/LockupDynamic.sol";

import {
    CreateWithTimestamps_Integration_Concrete_Test,
    Integration_Test
} from "../../lockup/create-with-timestamps/createWithTimestamps.t.sol";

contract CreateWithTimestampsLD_Integration_Concrete_Test is CreateWithTimestamps_Integration_Concrete_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();
        lockupModel = Lockup.Model.LOCKUP_DYNAMIC;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStreamWithSegments(LockupDynamic.Segment[] memory segments) internal returns (uint256) {
        return lockup.createWithTimestampsLD(_defaultParams.createWithTimestamps, segments);
    }

    function test_RevertWhen_SegmentCountZero()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
    {
        LockupDynamic.Segment[] memory segments;
        vm.expectRevert(Errors.SablierHelpers_SegmentCountZero.selector);
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_SegmentAmountsSumOverflows()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenSegmentCountNotZero
    {
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].amount = MAX_UINT128;
        segments[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_StartTimeGreaterThanFirstTimestamp()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenSegmentCountNotZero
        whenSegmentAmountsSumNotOverflow
    {
        // Change the timestamp of the first segment.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].timestamp = defaults.START_TIME() - 1 seconds;

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_StartTimeNotLessThanFirstSegmentTimestamp.selector,
                defaults.START_TIME(),
                segments[0].timestamp
            )
        );
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_StartTimeEqualsFirstTimestamp()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenSegmentCountNotZero
        whenSegmentAmountsSumNotOverflow
    {
        // Change the timestamp of the first segment.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].timestamp = defaults.START_TIME();

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_StartTimeNotLessThanFirstSegmentTimestamp.selector,
                defaults.START_TIME(),
                segments[0].timestamp
            )
        );
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_EndTimeNotEqualLastTimestamp()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenSegmentCountNotZero
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
    {
        _defaultParams.createWithTimestamps.timestamps.end = defaults.END_TIME() + 1 seconds;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_EndTimeNotEqualToLastSegmentTimestamp.selector,
                _defaultParams.createWithTimestamps.timestamps.end,
                _defaultParams.createWithTimestamps.timestamps.end - 1
            )
        );
        createDefaultStream();
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTokenNotNativeToken
        whenTokenContract
        whenSegmentCountNotZero
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
    {
        // Swap the segment timestamps.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        (segments[0].timestamp, segments[1].timestamp) = (segments[1].timestamp, segments[0].timestamp);

        // Expect the relevant error to be thrown.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_SegmentTimestampsNotOrdered.selector,
                index,
                segments[0].timestamp,
                segments[1].timestamp
            )
        );
        _defaultParams.createWithTimestamps.timestamps.end = segments[1].timestamp;
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_DepositAmountNotEqualSegmentAmountsSum()
        external
        whenNoDelegateCall
        whenShapeNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenSegmentCountNotZero
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
        whenTimestampsStrictlyIncreasing
    {
        setMsgSender(users.sender);

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + 100;

        // Prepare the params.
        _defaultParams.createWithTimestamps.depositAmount = depositAmount;

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierHelpers_DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                defaultDepositAmount
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
        whenSegmentCountNotZero
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
        whenTimestampsStrictlyIncreasing
        whenDepositAmountEqualsSegmentAmountsSum
    {
        IERC20 _usdt = IERC20(address(usdt));

        uint256 previousAggregateAmount = lockup.aggregateAmount(_usdt);

        // Update the default params.
        _defaultParams.createWithTimestamps.depositAmount = defaults.DEPOSIT_AMOUNT_6D();
        _defaultParams.createWithTimestamps.token = _usdt;
        _defaultParams.segments[0].amount = 2600e6;
        _defaultParams.segments[1].amount = 7400e6;

        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            token: _usdt,
            from: users.sender,
            to: address(lockup),
            value: _defaultParams.createWithTimestamps.depositAmount
        });

        // It should emit {CreateLockupDynamicStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupDynamic.CreateLockupDynamicStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(_usdt, _defaultParams.createWithTimestamps.depositAmount),
            segments: _defaultParams.segments
        });

        // Create the stream.
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId, _usdt);
        assertEq(lockup.getSegments(streamId), _defaultParams.segments);
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_DYNAMIC);
        assertEq(
            lockup.aggregateAmount(_usdt),
            previousAggregateAmount + _defaultParams.createWithTimestamps.depositAmount,
            "aggregateAmount"
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
        whenSegmentCountNotZero
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenEndTimeEqualsLastTimestamp
        whenTimestampsStrictlyIncreasing
        whenDepositAmountNotEqualSegmentAmountsSum
        whenTokenNotNativeToken
        whenTokenContract
    {
        uint256 previousAggregateAmount = lockup.aggregateAmount(dai);

        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            token: dai,
            from: users.sender,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // It should emit {CreateLockupDynamicStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupDynamic.CreateLockupDynamicStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(dai, defaults.DEPOSIT_AMOUNT()),
            segments: defaults.segments()
        });

        // Create the stream.
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId, dai);
        assertEq(lockup.getSegments(streamId), defaults.segments());
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_DYNAMIC);
        assertEq(lockup.aggregateAmount(dai), previousAggregateAmount + defaults.DEPOSIT_AMOUNT(), "aggregateAmount");
    }
}
