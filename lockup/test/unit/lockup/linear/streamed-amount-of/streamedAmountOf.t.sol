// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";

contract StreamedAmountOf_Linear_Unit_Test is Linear_Unit_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        Linear_Unit_Test.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNull.selector, nullStreamId));
        linear.streamedAmountOf(nullStreamId);
    }

    /// @dev it should return the correct streamed amount.
    function test_StreamedAmountOf_StreamDepleted() external {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        uint128 withdrawAmount = DEFAULT_DEPOSIT_AMOUNT;
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
        uint256 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint256 expectedStreamedAmount = withdrawAmount;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev it should return the correct streamed amount
    function test_StreamedAmountOf_StreamCanceled() external {
        vm.warp({ timestamp: DEFAULT_CLIFF_TIME });
        lockup.cancel(defaultStreamId);
        uint256 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint256 expectedStreamedAmount = DEFAULT_DEPOSIT_AMOUNT - DEFAULT_RETURNED_AMOUNT;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenStreamActive() {
        _;
    }

    /// @dev it should return zero.
    function test_StreamedAmountOf_CliffTimeInTheFuture() external whenStreamActive {
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenCliffTimeInThePast() {
        _;
    }

    /// @dev it should return the correct streamed amount.
    function test_StreamedAmountOf() external whenStreamActive whenCliffTimeInThePast {
        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Run the test.
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 2600e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
