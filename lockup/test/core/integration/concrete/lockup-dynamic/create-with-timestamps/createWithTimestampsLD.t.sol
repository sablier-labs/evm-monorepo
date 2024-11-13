// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { stdError } from "forge-std/src/StdError.sol";
import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Broker, Lockup, LockupDynamic } from "src/core/types/DataTypes.sol";
import { Lockup_Dynamic_Integration_Shared_Test } from "./../LockupDynamic.t.sol";

contract CreateWithTimestampsLD_Integration_Concrete_Test is Lockup_Dynamic_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Lockup_Dynamic_Integration_Shared_Test.setUp();
        streamId = lockup.nextStreamId();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(
            ISablierLockup.createWithTimestampsLD, (defaults.createWithTimestamps(), defaults.segments())
        );
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_SenderZeroAddress() external whenNoDelegateCall {
        vm.expectRevert(Errors.SablierLockup_SenderZeroAddress.selector);
        createDefaultStreamWithSenderLD(address(0));
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNoDelegateCall whenSenderNotZeroAddress {
        address recipient = address(0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, recipient));
        createDefaultStreamWithRecipientLD(recipient);
    }

    function test_RevertWhen_DepositAmountZero()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
    {
        // It is not possible to obtain a zero deposit amount from a non-zero total amount, because the `MAX_BROKER_FEE`
        // is hard coded to 10%.
        vm.expectRevert(Errors.SablierLockup_DepositAmountZero.selector);
        uint128 totalAmount = 0;
        createDefaultStreamWithTotalAmountLD(totalAmount);
    }

    function test_RevertWhen_StartTimeZero()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        vm.expectRevert(Errors.SablierLockup_StartTimeZero.selector);
        createDefaultStreamWithStartTimeLD(0);
    }

    function test_RevertWhen_SegmentCountZero()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
    {
        LockupDynamic.Segment[] memory segments;
        vm.expectRevert(Errors.SablierLockup_SegmentCountZero.selector);
        createDefaultStreamWithSegmentsLD(segments);
    }

    function test_RevertWhen_SegmentCountExceedsMaxValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenSegmentCountNotZero
    {
        uint256 segmentCount = defaults.MAX_COUNT() + 1;
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](segmentCount);
        segments[segmentCount - 1].timestamp = defaults.END_TIME();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_SegmentCountTooHigh.selector, segmentCount));
        createDefaultStreamWithSegmentsLD(segments);
    }

    function test_RevertWhen_SegmentAmountsSumOverflows()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
    {
        LockupDynamic.Segment[] memory segments = defaults.segments();
        segments[0].amount = MAX_UINT128;
        segments[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithSegmentsLD(segments);
    }

    function test_RevertWhen_StartTimeGreaterThanFirstTimestamp()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
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
                Errors.SablierLockup_StartTimeNotLessThanFirstSegmentTimestamp.selector,
                defaults.START_TIME(),
                segments[0].timestamp
            )
        );

        // Create the stream.
        createDefaultStreamWithSegmentsLD(segments);
    }

    function test_RevertWhen_StartTimeEqualsFirstTimestamp()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
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
                Errors.SablierLockup_StartTimeNotLessThanFirstSegmentTimestamp.selector,
                defaults.START_TIME(),
                segments[0].timestamp
            )
        );

        // Create the stream.
        createDefaultStreamWithSegmentsLD(segments);
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenSegmentCountNotZero
        whenSegmentCountNotExceedMaxValue
        whenSegmentAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
    {
        // Swap the segment timestamps.
        LockupDynamic.Segment[] memory segments = defaults.segments();
        (segments[0].timestamp, segments[1].timestamp) = (segments[1].timestamp, segments[0].timestamp);

        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestamps();
        params.endTime = segments[1].timestamp;
        // Expect the relevant error to be thrown.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_SegmentTimestampsNotOrdered.selector,
                index,
                segments[0].timestamp,
                segments[1].timestamp
            )
        );

        // Create the stream.
        lockup.createWithTimestampsLD(params, segments);
    }

    function test_RevertWhen_DepositAmountNotEqualSegmentAmountsSum()
        external
        whenNoDelegateCall
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
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        params.totalAmount = depositAmount;

        LockupDynamic.Segment[] memory segments = defaults.segments();

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                defaultDepositAmount
            )
        );

        // Create the stream.
        lockup.createWithTimestampsLD(params, segments);
    }

    function test_RevertWhen_BrokerFeeExceedsMaxValue()
        external
        whenNoDelegateCall
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
    {
        UD60x18 brokerFee = MAX_BROKER_FEE + ud(1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_BrokerFeeTooHigh.selector, brokerFee, MAX_BROKER_FEE)
        );
        createDefaultStreamWithBrokerLD(Broker({ account: users.broker, fee: brokerFee }));
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNoDelegateCall
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
    {
        address nonContract = address(8128);

        resetPrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Address.AddressEmptyCode.selector, nonContract));
        createDefaultStreamWithAssetLD(IERC20(nonContract));
    }

    function test_WhenAssetMissesERC20ReturnValue()
        external
        whenNoDelegateCall
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
        _testCreateWithTimestampsLD(address(usdt));
    }

    function test_WhenAssetNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
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
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupDynamicStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            segments: defaults.segments(),
            asset: IERC20(asset),
            cancelable: true,
            transferable: true,
            timestamps: defaults.lockupDynamicTimestamps(),
            broker: users.broker
        });

        // Create the stream.
        streamId = createDefaultStreamWithAssetLD(IERC20(asset));

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getAsset(streamId), IERC20(asset), "asset");
        assertEq(lockup.getEndTime(streamId), defaults.END_TIME(), "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertEq(lockup.isDepleted(streamId), false, "isDepleted");
        assertEq(lockup.isStream(streamId), true, "isStream");
        assertEq(lockup.isTransferable(streamId), true, "isTransferable");
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), defaults.START_TIME(), "startTime");
        assertEq(lockup.wasCanceled(streamId), false, "wasCanceled");
        assertEq(lockup.getSegments(streamId), defaults.segments(), "segments");

        // Assert that the stream's status is "PENDING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.PENDING;
        assertEq(actualStatus, expectedStatus);

        // It should bump the next stream ID.
        uint256 actualNextStreamId = lockup.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // It should mint the NFT.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
