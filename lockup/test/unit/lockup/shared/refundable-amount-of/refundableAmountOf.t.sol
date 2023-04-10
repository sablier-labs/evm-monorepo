// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract RefundableAmountOf_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenStreamNotActive() {
        _;
    }

    function test_RevertWhen_StreamNull() external whenStreamNotActive {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        lockup.refundableAmountOf(nullStreamId);
    }

    function test_RefundableAmountOf_StreamDepleted() external whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint256 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint256 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    function test_RefundableAmountOf_StreamCanceled() external whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        uint256 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint256 expectedRefundableAmount = 0;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }

    modifier whenStreamActive() {
        _;
    }

    function test_RefundableAmountOf() external whenStreamActive {
        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Get the streamed amount.
        uint128 streamedAmount = lockup.streamedAmountOf(defaultStreamId);

        // Run the test.
        uint256 actualRefundableAmount = lockup.refundableAmountOf(defaultStreamId);
        uint256 expectedRefundableAmount = DEFAULT_DEPOSIT_AMOUNT - streamedAmount;
        assertEq(actualRefundableAmount, expectedRefundableAmount, "refundableAmount");
    }
}
