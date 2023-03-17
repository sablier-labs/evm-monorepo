// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract ReturnableAmountOf_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenStreamNotActive() {
        _;
    }

    /// @dev it should return zero.
    function test_ReturnableAmountOf_StreamNull() external whenStreamNotActive {
        uint256 nullStreamId = 1729;
        uint256 actualReturnableAmount = lockup.returnableAmountOf(nullStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount, "returnableAmount");
    }

    /// @dev it should return zero.
    function test_ReturnableAmountOf_StreamCanceled() external whenStreamNotActive {
        lockup.cancel(defaultStreamId);
        uint256 actualReturnableAmount = lockup.returnableAmountOf(defaultStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount, "returnableAmount");
    }

    /// @dev it should return zero.
    function test_ReturnableAmountOf_StreamDepleted() external whenStreamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        uint256 actualReturnableAmount = lockup.returnableAmountOf(defaultStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount, "returnableAmount");
    }

    modifier whenStreamActive() {
        _;
    }

    /// @dev it should return the correct returnable amount.
    function test_ReturnableAmountOf() external whenStreamActive {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Get the streamed amount.
        uint128 streamedAmount = lockup.streamedAmountOf(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = lockup.returnableAmountOf(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_DEPOSIT_AMOUNT - streamedAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount, "returnableAmount");
    }
}
