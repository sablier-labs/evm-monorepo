// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract WithdrawMax_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Create the default stream.
        defaultStreamId = createDefaultStream();

        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    modifier whenCurrentTimeLessThanEndTime() {
        _;
    }

    /// @dev it should make the max withdrawal, update the withdrawn amount, and emit a {WithdrawFromLockupStream}
    /// event.
    function testFuzz_WithdrawMax(uint256 timeWarp) external whenCurrentTimeLessThanEndTime {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Get the withdraw amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectTransferCall({ to: users.recipient, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Make the max withdrawal.
        lockup.withdrawMax(defaultStreamId, users.recipient);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
