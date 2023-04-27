// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract WithdrawMultiple_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint40 internal immutable EARLY_STOP_TIME;
    address internal caller;
    uint128[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    constructor() {
        EARLY_STOP_TIME = WARP_26_PERCENT;
    }

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        createDefaultStreams();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2Lockup.withdrawMultiple, (defaultStreamIds, users.recipient, defaultAmounts));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertWhen_ToZeroAddress() external whenNoDelegateCall {
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: address(0), amounts: defaultAmounts });
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    function test_RevertWhen_ArrayCountsNotEqual() external whenNoDelegateCall whenToNonZeroAddress {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawArrayCountsNotEqual.selector, streamIds.length, amounts.length
            )
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenArrayCountsAreEqual() {
        _;
    }

    function test_WithdrawMultiple_ArrayCountsZero()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
    {
        uint256[] memory streamIds = new uint256[](0);
        uint128[] memory amounts = new uint128[](0);
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenArrayCountsNotZero() {
        _;
    }

    function test_RevertWhen_OnlyNull()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
    {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.withdrawMultiple({
            streamIds: Solarray.uint256s(nullStreamId),
            to: users.recipient,
            amounts: Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT)
        });
    }

    function test_RevertWhen_SomeNull()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
    {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0], defaultStreamIds[1], nullStreamId);

        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Expect a {Null} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier whenNoNull() {
        _;
    }

    function test_RevertWhen_AllStatusesEitherPendingOrDepleted()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
    {
        uint256[] memory streamIds = Solarray.uint256s(defaultStreamIds[0]);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_END_TIME });

        // Deplete the stream.
        lockup.withdrawMax({ streamId: defaultStreamIds[0], to: users.recipient });

        // Expect a {StreamDepleted} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, defaultStreamIds[0]));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({
            streamIds: streamIds,
            to: users.recipient,
            amounts: Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT)
        });
    }

    function test_RevertWhen_SomeStatusesEitherPendingOrDepleted()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
    {
        uint256 earlyStreamId = createDefaultStreamWithStartTime(getBlockTimestamp() + 1 seconds);
        uint256[] memory streamIds = Solarray.uint256s(earlyStreamId, defaultStreamIds[0], defaultStreamIds[1]);

        // Expect a {StreamPending} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamPending.selector, earlyStreamId));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    modifier whenNoStatusPendingOrDepleted() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerUnauthorized
    {
        // Transfer all streams to Alice.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[1] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[2] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerUnauthorized
    {
        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(users.eve);

        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, defaultStreamIds[0], defaultStreamIds[1]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: defaultAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerUnauthorized
    {
        // Transfer one of the streams to Eve.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: defaultStreamIds[0] });

        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
    }

    /// @dev This modifier runs the test in three different modes:
    /// - Stream's sender as caller
    /// - Stream's recipient as caller
    /// - Approved NFT operator as caller
    modifier whenCallerAuthorizedAllStreams() {
        caller = users.sender;
        _;
        createDefaultStreams();
        caller = users.recipient;
        _;
        createDefaultStreams();
        changePrank({ msgSender: users.recipient });
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });
        caller = users.operator;
        _;
    }

    function test_RevertWhen_SomeAmountsZero()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerAuthorizedAllStreams
    {
        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(DEFAULT_WITHDRAW_AMOUNT, 0, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, defaultStreamIds[1]));
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenNoAmountZero() {
        _;
    }

    function test_RevertWhen_SomeAmountsOverdraw()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerAuthorizedAllStreams
        whenNoAmountZero
    {
        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Run the test.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(defaultStreamIds[2]);
        uint128[] memory amounts = Solarray.uint128s(defaultAmounts[0], defaultAmounts[1], UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_Overdraw.selector, defaultStreamIds[2], UINT128_MAX, withdrawableAmount
            )
        );
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenNoAmountOverdraws() {
        _;
    }

    function test_WithdrawMultiple()
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerAuthorizedAllStreams
        whenNoAmountZero
        whenNoAmountOverdraws
    {
        // Warp into the future.
        vm.warp({ timestamp: EARLY_STOP_TIME });

        // Cancel the second stream.
        lockup.cancel(defaultStreamIds[1]);

        // Run the test with the caller provided in the modifier above.
        changePrank({ msgSender: caller });

        // Expect the withdrawals to be made.
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[0] });
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[1] });
        expectTransferCall({ to: users.recipient, amount: defaultAmounts[2] });

        // Expect multiple events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[0], to: users.recipient, amount: defaultAmounts[0] });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[1], to: users.recipient, amount: defaultAmounts[1] });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamIds[2], to: users.recipient, amount: defaultAmounts[2] });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });

        // Assert that the statuses have been updated.
        assertEq(lockup.statusOf(defaultStreamIds[0]), Lockup.Status.STREAMING, "status0");
        assertEq(lockup.statusOf(defaultStreamIds[1]), Lockup.Status.CANCELED, "status1");
        assertEq(lockup.statusOf(defaultStreamIds[2]), Lockup.Status.DEPLETED, "status2");

        // Assert that the withdrawn amounts have been updated.
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[0]), defaultAmounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[1]), defaultAmounts[1], "withdrawnAmount1");
        assertEq(lockup.getWithdrawnAmount(defaultStreamIds[2]), defaultAmounts[2], "withdrawnAmount2");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(defaultStreamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(defaultStreamIds[1]), users.recipient, "NFT owner1");
        assertEq(lockup.getRecipient(defaultStreamIds[2]), users.recipient, "NFT owner2");
    }

    /// @dev Creates the default streams used throughout the tests.
    function createDefaultStreams() internal {
        // Warp back to the original timestamp.
        vm.warp({ timestamp: MARCH_1_2023 });

        // Define the default amounts.
        defaultAmounts = new uint128[](3);
        defaultAmounts[0] = DEFAULT_WITHDRAW_AMOUNT;
        defaultAmounts[1] = DEFAULT_WITHDRAW_AMOUNT / 2;
        defaultAmounts[2] = DEFAULT_DEPOSIT_AMOUNT;

        // Create three streams:
        // 1. A default stream
        // 2. A stream meant to be canceled before the withdrawal is made
        // 3. A stream with an early end time
        defaultStreamIds = new uint256[](3);
        defaultStreamIds[0] = createDefaultStream();
        defaultStreamIds[1] = createDefaultStream();
        defaultStreamIds[2] = createDefaultStreamWithEndTime(EARLY_STOP_TIME);
    }
}
