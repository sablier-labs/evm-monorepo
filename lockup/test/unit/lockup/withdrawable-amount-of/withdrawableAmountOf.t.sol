// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract WithdrawableAmountOf_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.withdrawableAmountOf(nullStreamId);
    }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    modifier whenStreamHasBeenCanceled() {
        _;
    }

    function test_WithdrawableAmountOf_StreamHasBeenCanceled_StatusCanceled()
        external
        whenNotNull
        whenStreamHasBeenCanceled
    {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint256 expectedWithdrawableAmount = DEFAULT_DEPOSIT_AMOUNT - DEFAULT_REFUND_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    /// @dev This test warps a second time to ensure that {withdrawableAmountOf} ignores the current time.
    function test_WithdrawableAmountOf_StreamHasBeenCanceled_StatusDepleted()
        external
        whenNotNull
        whenStreamHasBeenCanceled
    {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME + 10 seconds });
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenStreamHasNotBeenCanceled() {
        _;
    }

    function test_WithdrawableAmountOf_StatusPending() external whenNotNull whenStreamHasNotBeenCanceled {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_WithdrawableAmountOf_StatusSettled() external whenNotNull whenStreamHasNotBeenCanceled {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_DEPOSIT_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    function test_WithdrawableAmountOf_StatusDepleted() external whenNotNull whenStreamHasNotBeenCanceled {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint128 actualWithdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
