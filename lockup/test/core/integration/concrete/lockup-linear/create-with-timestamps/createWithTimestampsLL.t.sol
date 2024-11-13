// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Broker, Lockup } from "src/core/types/DataTypes.sol";
import { Lockup_Linear_Integration_Shared_Test } from "./../LockupLinear.t.sol";

contract CreateWithTimestampsLL_Integration_Concrete_Test is Lockup_Linear_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public override {
        Lockup_Linear_Integration_Shared_Test.setUp();
        streamId = lockup.nextStreamId();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(
            ISablierLockup.createWithTimestampsLT, (defaults.createWithTimestamps(), defaults.tranches())
        );
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_SenderZeroAddress() external whenNoDelegateCall {
        vm.expectRevert(Errors.SablierLockup_SenderZeroAddress.selector);
        createDefaultStreamWithSenderLL(address(0));
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNoDelegateCall whenSenderNotZeroAddress {
        address recipient = address(0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, recipient));
        createDefaultStreamWithRecipientLL(recipient);
    }

    function test_RevertWhen_DepositAmountZero()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
    {
        vm.expectRevert(Errors.SablierLockup_DepositAmountZero.selector);
        createDefaultStreamWithTotalAmountLL(0);
    }

    function test_RevertWhen_StartTimeZero()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        uint40 cliffTime = defaults.CLIFF_TIME();
        uint40 endTime = defaults.END_TIME();

        vm.expectRevert(Errors.SablierLockup_StartTimeZero.selector);
        createDefaultStreamWithTimestampsLL(Lockup.Timestamps({ start: 0, cliff: cliffTime, end: endTime }));
    }

    function test_RevertWhen_StartTimeNotLessThanEndTime()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeZero
    {
        uint40 startTime = defaults.END_TIME();
        uint40 endTime = defaults.START_TIME();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_StartTimeNotLessThanEndTime.selector, startTime, endTime)
        );
        createDefaultStreamWithTimestampsLL(Lockup.Timestamps({ start: startTime, cliff: 0, end: endTime }));
    }

    function test_WhenStartTimeLessThanEndTime()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeZero
    {
        createDefaultStreamWithTimestampsLL(
            Lockup.Timestamps({ start: defaults.START_TIME(), cliff: 0, end: defaults.END_TIME() })
        );

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getAsset(streamId), dai, "asset");
        assertEq(lockup.getEndTime(streamId), defaults.END_TIME(), "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertEq(lockup.isDepleted(streamId), false, "isDepleted");
        assertEq(lockup.isStream(streamId), true, "isStream");
        assertEq(lockup.isTransferable(streamId), true, "isTransferable");
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), defaults.START_TIME(), "startTime");
        assertEq(lockup.wasCanceled(streamId), false, "wasCanceled");
        assertEq(lockup.getCliffTime(streamId), 0, "cliff");

        // Assert that the next stream ID has been bumped.
        uint256 actualNextStreamId = lockup.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the NFT has been minted.
        address actualNFTOwner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    function test_RevertWhen_StartTimeNotLessThanCliffTime()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeNotZero
    {
        uint40 startTime = defaults.CLIFF_TIME();
        uint40 cliffTime = defaults.START_TIME();
        uint40 endTime = defaults.END_TIME();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_StartTimeNotLessThanCliffTime.selector, startTime, cliffTime)
        );
        createDefaultStreamWithTimestampsLL(Lockup.Timestamps({ start: startTime, cliff: cliffTime, end: endTime }));
    }

    function test_RevertWhen_CliffTimeNotLessThanEndTime()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
    {
        uint40 startTime = defaults.START_TIME();
        uint40 cliffTime = defaults.END_TIME();
        uint40 endTime = defaults.CLIFF_TIME();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_CliffTimeNotLessThanEndTime.selector, cliffTime, endTime)
        );
        createDefaultStreamWithTimestampsLL(Lockup.Timestamps({ start: startTime, cliff: cliffTime, end: endTime }));
    }

    function test_RevertWhen_BrokerFeeExceedsMaxValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
    {
        UD60x18 brokerFee = MAX_BROKER_FEE + ud(1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_BrokerFeeTooHigh.selector, brokerFee, MAX_BROKER_FEE)
        );
        createDefaultStreamWithBrokerLL(Broker({ account: users.broker, fee: brokerFee }));
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
        whenBrokerFeeNotExceedMaxValue
    {
        address nonContract = address(8128);
        vm.expectRevert(abi.encodeWithSelector(Address.AddressEmptyCode.selector, nonContract));
        createDefaultStreamWithAssetLL(IERC20(nonContract));
    }

    function test_WhenAssetMissesERC20ReturnValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
        whenBrokerFeeNotExceedMaxValue
        whenAssetContract
    {
        _testCreateWithTimestamps(address(usdt));
    }

    function test_WhenAssetNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenCliffTimeNotZero
        whenStartTimeLessThanCliffTime
        whenCliffTimeLessThanEndTime
        whenBrokerFeeNotExceedMaxValue
        whenAssetContract
    {
        _testCreateWithTimestamps(address(dai));
    }

    /// @dev Shared logic between {test_CreateWithTimestamps_AssetMissingReturnValue} and {test_CreateWithTimestamps}.
    function _testCreateWithTimestamps(address asset) private {
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

        // It should emit {MetadataUpdate} and {CreateLockupLinearStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupLinearStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            asset: IERC20(asset),
            cancelable: true,
            transferable: true,
            timestamps: defaults.lockupLinearTimestamps(),
            broker: users.broker
        });

        // Create the stream.
        createDefaultStreamWithAssetLL(IERC20(asset));

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
        assertEq(lockup.getCliffTime(streamId), defaults.CLIFF_TIME(), "cliff");

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
