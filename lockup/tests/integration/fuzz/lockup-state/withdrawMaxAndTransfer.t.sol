// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract WithdrawMaxAndTransfer_Integration_Fuzz_Test is Integration_Test {
    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - New recipient same and different from the current one
    /// - Withdrawable amount zero and not zero
    function testFuzz_WithdrawMaxAndTransfer(
        uint256 timeJump,
        address newRecipient
    )
        external
        whenNoDelegateCall
        givenNotNull
        whenCallerRecipient
        givenNotBurnedNFT
        givenTransferableStream
    {
        vm.assume(newRecipient != address(0));
        timeJump = _bound(timeJump, 0, defaults.TOTAL_DURATION() * 2);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Get the withdraw amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(ids.defaultStream);

        if (withdrawAmount > 0) {
            // Expect the tokens to be transferred to the fuzzed recipient.
            expectCallToTransfer({ to: users.recipient, value: withdrawAmount });

            // Expect the relevant event to be emitted.
            vm.expectEmit({ emitter: address(lockup) });
            emit ISablierLockup.WithdrawFromLockupStream({
                streamId: ids.defaultStream,
                to: users.recipient,
                token: dai,
                amount: withdrawAmount
            });
        }

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC721.Transfer({ from: users.recipient, to: newRecipient, tokenId: ids.defaultStream });

        // Make the max withdrawal and transfer the NFT.
        lockup.withdrawMaxAndTransfer({ streamId: ids.defaultStream, newRecipient: newRecipient });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(ids.defaultStream);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the fuzzed recipient is the new stream recipient (and NFT owner).
        address actualRecipient = lockup.getRecipient(ids.defaultStream);
        address expectedRecipient = newRecipient;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
