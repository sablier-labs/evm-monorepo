// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract WithdrawMax_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream.
        defaultStreamId = createDefaultStream();

        // Make the recipient the caller in this test suite.
        changePrank({ who: users.recipient });
    }

    /// @dev it should make the withdrawal and mark the stream as depleted.
    function test_WithdrawMax_CurrentTimeEqualToStopTime() external {
        // Warp to the end of the stream.
        vm.warp({ timestamp: DEFAULT_STOP_TIME });

        // Make the max withdrawal.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Assert that the stream was marked as depleted.
        Status actualStatus = lockup.getStatus(defaultStreamId);
        Status expectedStatus = Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the NFT was not burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    modifier currentTimeLessThanStopTime() {
        _;
    }

    /// @dev it should make the max withdrawal, update the withdrawn amount, and emit a {WithdrawFromLockupStream}
    /// event.
    function test_WithdrawMax() external currentTimeLessThanStopTime {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Get the withdraw amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount)));

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            amount: withdrawAmount
        });

        // Make the max withdrawal.
        lockup.withdrawMax(defaultStreamId, users.recipient);

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
