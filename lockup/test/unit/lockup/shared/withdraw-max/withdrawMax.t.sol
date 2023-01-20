// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";

import { Shared_Test } from "../SharedTest.t.sol";

abstract contract WithdrawMax_Test is Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        super.setUp();

        // Create the default stream.
        defaultStreamId = createDefaultStream();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should make the withdrawal and mark the stream as depleted.
    function test_WithdrawMax_CurrentTimeEqualToStopTime() external {
        // Warp to the end of the stream.
        vm.warp({ timestamp: DEFAULT_STOP_TIME });

        // Make the withdrawal.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Assert that the stream was marked as depleted.
        Status actualStatus = lockup.getStatus(defaultStreamId);
        Status expectedStatus = Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the NFT was not burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner);
    }

    modifier currentTimeLessThanStopTime() {
        _;
    }

    /// @dev it should make the max withdrawal, update the withdrawn amount, and emit a WithdrawFromLockupStream event.
    function testFuzz_WithdrawMax(uint256 timeWarp) external currentTimeLessThanStopTime {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawAmount = lockup.getWithdrawableAmount(defaultStreamId);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount)));

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            amount: withdrawAmount
        });

        // Make the withdrawal.
        lockup.withdrawMax(defaultStreamId, users.recipient);

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
