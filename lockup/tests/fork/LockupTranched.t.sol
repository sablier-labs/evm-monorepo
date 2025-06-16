// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockupTranched } from "src/interfaces/ISablierLockupTranched.sol";
import { Lockup } from "src/types/Lockup.sol";
import { Lockup_Fork_Test } from "./Lockup.t.sol";

abstract contract Lockup_Tranched_Fork_Test is Lockup_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) Lockup_Fork_Test(forkToken) {
        lockupModel = Lockup.Model.LOCKUP_TRANCHED;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checklist:
    ///
    /// - It should perform all expected ERC-20 transfers
    /// - It should create the stream
    /// - It should bump the next stream ID
    /// - It should mint the NFT
    /// - It should emit a {CreateLockupTranchedStream} event
    /// - It may make a withdrawal and pay a fee
    /// - It may update the withdrawn amounts
    /// - It may emit a {WithdrawFromLockupStream} event
    /// - It may cancel the stream
    /// - It may emit a {CancelLockupStream} event
    ///
    /// Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the recipient, and sender
    /// - Multiple values for the total amount
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Start time equal and not equal to the first tranche timestamp
    /// - Multiple values for the withdraw amount, including zero
    /// - The whole gamut of stream statuses
    function testForkFuzz_CreateWithdrawCancel(Params memory params) external {
        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Fuzz the tranche timestamps.
        vm.assume(params.tranches.length != 0);

        // Bound the fuzzed parameters and load values into `vars`.
        preCreateStream(params);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: vars.streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupTranched.CreateLockupTranchedStream({
            streamId: vars.streamId,
            commonParams: defaults.lockupCreateEvent({ params: params.create, token_: FORK_TOKEN }),
            tranches: params.tranches
        });

        // Create the stream.
        lockup.createWithTimestampsLT(params.create, params.tranches);

        // Assert that the stream is created with the correct parameters.
        assertEq({ streamId: vars.streamId, lockup: lockup, expectedLockup: params.create });
        assertEq(lockup.getTranches(vars.streamId), params.tranches);

        // Update the streamed amount.
        vars.streamedAmount = calculateStreamedAmountLT(params.tranches, params.create.depositAmount);

        // Run post-create assertions and update token balances in `vars`.
        postCreateStream(params);

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Bound the warp timestamp.
        params.warpTimestamp = boundUint40(
            params.warpTimestamp, params.create.timestamps.start, params.create.timestamps.end + 100 seconds
        );

        // Simulate the passage of time.
        vm.warp({ newTimestamp: params.warpTimestamp });

        // Update the streamed amount.
        vars.streamedAmount = calculateStreamedAmountLT(params.tranches, params.create.depositAmount);

        // Run the fork test for withdraw function and update the parameters.
        withdraw(params);

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Run the cancel test.
        cancel(params);
    }
}
