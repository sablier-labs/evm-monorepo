// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { stdError } from "forge-std/src/StdError.sol";
import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import {
    CreateWithTimestamps_Integration_Concrete_Test,
    Integration_Test
} from "../../lockup-base/create-with-timestamps/createWithTimestamps.t.sol";

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
        whenShapeNameNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
    {
        LockupDynamic.Segment[] memory segments;
        vm.expectRevert(Errors.SablierHelpers_SegmentCountZero.selector);
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_SegmentCountExceedsMaxValue()
        external
        whenNoDelegateCall
        whenShapeNameNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenSegmentCountNotZero
    {
        uint256 segmentCount = defaults.MAX_COUNT() + 1;
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentCount);
        segments[segmentCount - 1].timestamp = defaults.END_TIME();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierHelpers_SegmentCountTooHigh.selector, segmentCount));
        createDefaultStreamWithSegments(segments);
    }

    function test_RevertWhen_SegmentAmountsSumOverflows()
        external
        whenNoDelegateCall
        whenShapeNameNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
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
        whenShapeNameNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
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
        whenShapeNameNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
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

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenShapeNameNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
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
        whenShapeNameNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTimestampsStrictlyIncreasing
    {
        resetPrank({ msgSender: users.sender });

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + 100;

        // Prepare the params.
        _defaultParams.createWithTimestamps.broker = defaults.brokerNull();
        _defaultParams.createWithTimestamps.totalAmount = depositAmount;

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

    function test_WhenAssetMissesERC20ReturnValue()
        external
        whenNoDelegateCall
        whenShapeNameNotExceed32Bytes
        whenBrokerFeeNotExceedMaxValue
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenAssetContract
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTimestampsStrictlyIncreasing
        whenDepositAmountEqualsSegmentAmountsSum
    {
        _testCreateWithTimestampsLD(address(usdt));
    }

    function test_WhenAssetNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
        whenShapeNameNotExceed32Bytes
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTimestampsStrictlyIncreasing
        whenDepositAmountNotEqualSegmentAmountsSum
        whenBrokerFeeNotExceedMaxValue
        whenAssetContract
    {
        _testCreateWithTimestampsLD(address(dai));
    }

    function _testCreateWithTimestampsLD(address asset) private {
        // Make the Sender the stream's funder.
        address funder = users.sender;

        uint256 expectedStreamId = lockup.nextStreamId();

        // It should perform the ERC-20 transfers.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: address(lockup),
            value: defaults.DEPOSIT_AMOUNT()
        });

        // Expect the broker fee to be paid to the broker.
        expectCallToTransferFrom({
            asset: IERC20(asset),
            from: funder,
            to: users.broker,
            value: defaults.BROKER_FEE_AMOUNT()
        });

        // It should emit {CreateLockupDynamicStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupDynamicStream({
            streamId: expectedStreamId,
            commonParams: defaults.lockupCreateEvent(IERC20(asset)),
            segments: defaults.segments()
        });

        // Create the stream.
        _defaultParams.createWithTimestamps.asset = IERC20(asset);
        uint256 streamId = createDefaultStream();

        // It should create the stream.
        assertEqStream(streamId);
        assertEq(lockup.getAsset(streamId), IERC20(asset), "asset");
        assertEq(lockup.getSegments(streamId), defaults.segments());
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_DYNAMIC);
    }
}
