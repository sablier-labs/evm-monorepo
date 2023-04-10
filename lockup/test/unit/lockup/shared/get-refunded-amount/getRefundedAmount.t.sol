// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetRefundedAmount_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();
    }

    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        lockup.getRefundedAmount(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    function test_GetRefundedAmount_StreamActive() external whenStreamNonNull {
        uint128 actualReturnedAmount = lockup.getRefundedAmount(streamId);
        uint128 expectedReturnedAmount = 0;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "refundedAmount");
    }

    function test_GetRefundedAmount_StreamDepleted() external whenStreamNonNull {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });
        uint128 actualReturnedAmount = lockup.getRefundedAmount(streamId);
        uint128 expectedReturnedAmount = 0;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "refundedAmount");
    }

    function test_GetRefundedAmount_StreamCanceled() external whenStreamNonNull {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(streamId);
        uint128 actualReturnedAmount = lockup.getRefundedAmount(streamId);
        uint128 expectedReturnedAmount = DEFAULT_RETURNED_AMOUNT;
        assertEq(actualReturnedAmount, expectedReturnedAmount, "refundedAmount");
    }
}
