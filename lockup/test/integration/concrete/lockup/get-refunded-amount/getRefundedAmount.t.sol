// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract GetRefundedAmount_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.getRefundedAmount(nullStreamId);
    }

    modifier whenNotNull() {
        defaultStreamId = createDefaultStream();
        _;
    }

    modifier whenStreamHasBeenCanceled() {
        _;
    }

    function test_GetRefundedAmount_StreamHasBeenCanceled_StatusCanceled()
        external
        whenNotNull
        whenStreamHasBeenCanceled
    {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        uint128 actualRefundedAmount = lockup.getRefundedAmount(defaultStreamId);
        uint128 expectedRefundedAmount = defaults.REFUND_AMOUNT();
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");
    }

    function test_GetRefundedAmount_StreamHasBeenCanceled_StatusDepleted()
        external
        whenNotNull
        whenStreamHasBeenCanceled
    {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(defaultStreamId);
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint128 actualRefundedAmount = lockup.getRefundedAmount(defaultStreamId);
        uint128 expectedRefundedAmount = defaults.REFUND_AMOUNT();
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");
    }

    modifier whenStreamHasNotBeenCanceled() {
        _;
    }

    function test_GetRefundedAmount_StatusPending() external whenNotNull whenStreamHasNotBeenCanceled {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        uint128 actualRefundedAmount = lockup.getRefundedAmount(defaultStreamId);
        uint128 expectedRefundedAmount = 0;
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");
    }

    function test_GetRefundedAmount_StatusStreaming() external whenNotNull whenStreamHasNotBeenCanceled {
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        uint128 actualRefundedAmount = lockup.getRefundedAmount(defaultStreamId);
        uint128 expectedRefundedAmount = 0;
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");
    }

    function test_GetRefundedAmount_StatusSettled() external whenNotNull whenStreamHasNotBeenCanceled {
        vm.warp({ timestamp: defaults.END_TIME() });
        uint128 actualRefundedAmount = lockup.getRefundedAmount(defaultStreamId);
        uint128 expectedRefundedAmount = 0;
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");
    }

    function test_GetRefundedAmount_StatusDepleted() external whenNotNull whenStreamHasNotBeenCanceled {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint128 actualRefundedAmount = lockup.getRefundedAmount(defaultStreamId);
        uint128 expectedRefundedAmount = 0;
        assertEq(actualRefundedAmount, expectedRefundedAmount, "refundedAmount");
    }
}
