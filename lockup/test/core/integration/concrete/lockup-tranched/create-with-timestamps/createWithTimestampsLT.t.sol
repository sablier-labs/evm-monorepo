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
import { Broker, Lockup, LockupTranched } from "src/core/types/DataTypes.sol";
import { Lockup_Tranched_Integration_Shared_Test } from "./../LockupTranched.t.sol";

contract CreateWithTimestampsLT_Integration_Concrete_Test is Lockup_Tranched_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        Lockup_Tranched_Integration_Shared_Test.setUp();
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
        createDefaultStreamWithSenderLT(address(0));
    }

    function test_RevertWhen_RecipientZeroAddress() external whenNoDelegateCall whenSenderNotZeroAddress {
        address recipient = address(0);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, recipient));
        createDefaultStreamWithRecipientLT(recipient);
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
        createDefaultStreamWithTotalAmountLT(totalAmount);
    }

    function test_RevertWhen_StartTimeZero()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
    {
        vm.expectRevert(Errors.SablierLockup_StartTimeZero.selector);
        createDefaultStreamWithStartTimeLT(0);
    }

    function test_RevertWhen_TrancheCountZero()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
    {
        LockupTranched.Tranche[] memory tranches;
        vm.expectRevert(Errors.SablierLockup_TrancheCountZero.selector);
        createDefaultStreamWithTranchesLT(tranches);
    }

    function test_RevertWhen_TrancheCountExceedsMaxValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
    {
        uint256 trancheCount = defaults.MAX_COUNT() + 1;
        LockupTranched.Tranche[] memory tranches = new LockupTranched.Tranche[](trancheCount);
        tranches[trancheCount - 1].timestamp = defaults.END_TIME();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_TrancheCountTooHigh.selector, trancheCount));
        createDefaultStreamWithTranchesLT(tranches);
    }

    function test_RevertWhen_TrancheAmountsSumOverflows()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
    {
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].amount = MAX_UINT128;
        tranches[1].amount = 1;
        vm.expectRevert(stdError.arithmeticError);
        createDefaultStreamWithTranchesLT(tranches);
    }

    function test_RevertWhen_StartTimeGreaterThanFirstTimestamp()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
    {
        // Change the timestamp of the first tranche.
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].timestamp = defaults.START_TIME() - 1 seconds;

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                defaults.START_TIME(),
                tranches[0].timestamp
            )
        );

        // Create the stream.
        createDefaultStreamWithTranchesLT(tranches);
    }

    function test_RevertWhen_StartTimeEqualsFirstTimestamp()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
    {
        // Change the timestamp of the first tranche.
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        tranches[0].timestamp = defaults.START_TIME();

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_StartTimeNotLessThanFirstTrancheTimestamp.selector,
                defaults.START_TIME(),
                tranches[0].timestamp
            )
        );

        // Create the stream.
        createDefaultStreamWithTranchesLT(tranches);
    }

    function test_RevertWhen_TimestampsNotStrictlyIncreasing()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
    {
        // Swap the tranche timestamps.
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        (tranches[0].timestamp, tranches[1].timestamp) = (tranches[1].timestamp, tranches[0].timestamp);

        // Expect the relevant error to be thrown.
        uint256 index = 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_TrancheTimestampsNotOrdered.selector,
                index,
                tranches[0].timestamp,
                tranches[1].timestamp
            )
        );

        // Create the stream.
        createDefaultStreamWithTranchesLT(tranches);
    }

    function test_RevertWhen_DepositAmountNotEqualTrancheAmountsSum()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
    {
        resetPrank({ msgSender: users.sender });

        // Adjust the default deposit amount.
        uint128 defaultDepositAmount = defaults.DEPOSIT_AMOUNT();
        uint128 depositAmount = defaultDepositAmount + 100;

        // Prepare the params.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        params.totalAmount = depositAmount;

        LockupTranched.Tranche[] memory tranches = defaults.tranches();

        // Expect the relevant error to be thrown.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_DepositAmountNotEqualToTrancheAmountsSum.selector,
                depositAmount,
                defaultDepositAmount
            )
        );

        // Create the stream.
        lockup.createWithTimestampsLT(params, tranches);
    }

    function test_RevertWhen_BrokerFeeExceedsMaxValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
        whenDepositAmountNotEqualTrancheAmountsSum
    {
        UD60x18 brokerFee = MAX_BROKER_FEE + ud(1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_BrokerFeeTooHigh.selector, brokerFee, MAX_BROKER_FEE)
        );
        createDefaultStreamWithBrokerLT(Broker({ account: users.broker, fee: brokerFee }));
    }

    function test_RevertWhen_AssetNotContract()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
        whenDepositAmountNotEqualTrancheAmountsSum
        whenBrokerFeeNotExceedMaxValue
    {
        address nonContract = address(8128);

        resetPrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Address.AddressEmptyCode.selector, nonContract));
        createDefaultStreamWithAssetLT(IERC20(nonContract));
    }

    function test_WhenAssetMissesERC20ReturnValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
        whenDepositAmountNotEqualTrancheAmountsSum
        whenBrokerFeeNotExceedMaxValue
        whenAssetContract
    {
        testCreateWithTimestamps(address(usdt));
    }

    function test_WhenAssetNotMissERC20ReturnValue()
        external
        whenNoDelegateCall
        whenSenderNotZeroAddress
        whenRecipientNotZeroAddress
        whenDepositAmountNotZero
        whenStartTimeNotZero
        whenTrancheCountNotZero
        whenTrancheCountNotExceedMaxValue
        whenTrancheAmountsSumNotOverflow
        whenStartTimeLessThanFirstTimestamp
        whenTrancheTimestampsAreOrdered
        whenDepositAmountNotEqualTrancheAmountsSum
        whenBrokerFeeNotExceedMaxValue
        whenAssetContract
    {
        testCreateWithTimestamps(address(dai));
    }

    /// @dev Shared logic between {test_CreateWithTimestamps_AssetMissingReturnValue} and {test_CreateWithTimestamps}.
    function testCreateWithTimestamps(address asset) internal {
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

        // It should emit {CreateLockupTranchedStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockup.CreateLockupTranchedStream({
            streamId: streamId,
            funder: funder,
            sender: users.sender,
            recipient: users.recipient,
            amounts: defaults.lockupCreateAmounts(),
            tranches: defaults.tranches(),
            asset: IERC20(asset),
            cancelable: true,
            transferable: true,
            timestamps: defaults.lockupTranchedTimestamps(),
            broker: users.broker
        });

        // It should create the stream.
        streamId = createDefaultStreamWithAssetLT(IERC20(asset));

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
        assertEq(lockup.getTranches(streamId), defaults.tranches(), "tranches");

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
