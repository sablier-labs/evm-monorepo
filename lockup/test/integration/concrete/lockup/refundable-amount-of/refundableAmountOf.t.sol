// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract RefundableAmountOf_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.refundableAmountOf(nullStreamId);
    }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    function test_RefundableAmountOf_StreamNotCancelable() external whenNotNull {
        uint256 streamId = createDefaultStreamNotCancelable();
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(streamId);
        uint128 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    modifier whenStreamIsCancelable() {
        _;
    }

    modifier whenStreamHasBeenCanceled() {
        _;
    }

    function test_RefundableAmountOf_StreamHasBeenCanceled_StatusCanceled()
        external
        whenNotNull
        whenStreamIsCancelable
        whenStreamHasBeenCanceled
    {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    /// @dev This test warps a second time to ensure that {refundableAmountOf} ignores the current time.
    function test_RefundableAmountOf_StreamHasBeenCanceled_StatusDepleted()
        external
        whenNotNull
        whenStreamIsCancelable
        whenStreamHasBeenCanceled
    {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.warp({ timestamp: defaults.CLIFF_TIME() + 10 seconds });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    modifier whenStreamHasNotBeenCanceled() {
        _;
    }

    function test_RefundableAmountOf_StatusPending()
        external
        whenNotNull
        whenStreamIsCancelable
        whenStreamHasNotBeenCanceled
    {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }

    function test_RefundableAmountOf_StatusStreaming()
        external
        whenNotNull
        whenStreamIsCancelable
        whenStreamHasNotBeenCanceled
    {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = defaults.REFUND_AMOUNT();
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }

    function test_RefundableAmountOf_StatusSettled()
        external
        whenNotNull
        whenStreamIsCancelable
        whenStreamHasNotBeenCanceled
    {
        vm.warp({ timestamp: defaults.END_TIME() });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = 0;
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }

    function test_RefundableAmountOf_StatusDepleted()
        external
        whenNotNull
        whenStreamIsCancelable
        whenStreamHasNotBeenCanceled
    {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint128 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint128 expectedReturnableAmount = 0;
        assertEq(actualRefundableAmount, expectedReturnableAmount, "refundableAmount");
    }
}
