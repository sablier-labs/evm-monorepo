// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetReturnableAmount_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should return zero.
    function test_GetReturnableAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint256 actualReturnableAmount = lockup.getReturnableAmount(nullStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount, "returnableAmount");
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return the correct returnable amount.
    function test_GetReturnableAmount() external streamNonNull {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Get the streamed amount.
        uint128 streamedAmount = lockup.getStreamedAmount(defaultStreamId);

        // Run the test.
        uint256 actualReturnableAmount = lockup.getReturnableAmount(defaultStreamId);
        uint256 expectedReturnableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - streamedAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount, "returnableAmount");
    }
}
