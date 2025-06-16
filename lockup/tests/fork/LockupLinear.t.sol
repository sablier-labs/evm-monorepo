// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockupLinear } from "src/interfaces/ISablierLockupLinear.sol";
import { Lockup } from "src/types/Lockup.sol";
import { Lockup_Fork_Test } from "./Lockup.t.sol";

abstract contract Lockup_Linear_Fork_Test is Lockup_Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) Lockup_Fork_Test(forkToken) {
        lockupModel = Lockup.Model.LOCKUP_LINEAR;
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
    /// - It should emit a {MetadataUpdate} event
    /// - It should emit a {CreateLockupLinearStream} event
    /// - It may make a withdrawal and pay a fee
    /// - It may update the withdrawn amounts
    /// - It may emit a {WithdrawFromLockupStream} event
    /// - It may cancel the stream
    /// - It may emit a {CancelLockupStream} event
    ///
    /// Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the sender, and recipient
    /// - Multiple values for the deposit amount
    /// - Multiple values for the withdraw amount, including zero
    /// - Start time in the past
    /// - Start time in the present
    /// - Start time in the future
    /// - Multiple values for the cliff time and the end time
    /// - Cliff time zero and not zero
    /// - The whole gamut of stream statuses
    function testForkFuzz_CreateWithdrawCancel(Params memory params) external {
        /*//////////////////////////////////////////////////////////////////////////
                                            CREATE
        //////////////////////////////////////////////////////////////////////////*/

        // Bound the fuzzed parameters and load values into `vars`.
        preCreateStream(params);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: vars.streamId });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupLinear.CreateLockupLinearStream({
            streamId: vars.streamId,
            commonParams: defaults.lockupCreateEvent({ params: params.create, token_: FORK_TOKEN }),
            cliffTime: params.cliffTime,
            unlockAmounts: params.unlockAmounts
        });

        // Create the stream.
        lockup.createWithTimestampsLL(params.create, params.unlockAmounts, params.cliffTime);

        // Assert that the stream is created with the correct parameters.
        assertEq({ lockup: lockup, streamId: vars.streamId, expectedLockup: params.create });
        assertEq(lockup.getCliffTime(vars.streamId), params.cliffTime, "cliffTime");
        assertEq(lockup.getUnlockAmounts(vars.streamId), params.unlockAmounts);
        assertEq(lockup.getLockupModel(vars.streamId), Lockup.Model.LOCKUP_LINEAR);

        // Update the streamed amount.
        vars.streamedAmount = calculateStreamedAmountLL(
            params.create.timestamps.start,
            params.cliffTime,
            params.create.timestamps.end,
            params.create.depositAmount,
            params.unlockAmounts
        );

        // Run post-create assertions and update token balances in `vars`.
        postCreateStream(params);

        /*//////////////////////////////////////////////////////////////////////////
                                          WITHDRAW
        //////////////////////////////////////////////////////////////////////////*/

        // Bound the warp timestamp according to the cliff status, if it exists.
        if (vars.hasCliff) {
            params.warpTimestamp =
                boundUint40(params.warpTimestamp, params.cliffTime, params.create.timestamps.end + 100 seconds);
        } else {
            params.warpTimestamp = boundUint40(
                params.warpTimestamp,
                params.create.timestamps.start + 1 seconds,
                params.create.timestamps.end + 100 seconds
            );
        }

        // Simulate the passage of time.
        vm.warp({ newTimestamp: params.warpTimestamp });

        // Update the streamed amount.
        vars.streamedAmount = calculateStreamedAmountLL(
            params.create.timestamps.start,
            params.cliffTime,
            params.create.timestamps.end,
            params.create.depositAmount,
            params.unlockAmounts
        );

        // Run the fork test for withdraw function and update the parameters.
        withdraw(params);

        /*//////////////////////////////////////////////////////////////////////////
                                          CANCEL
        //////////////////////////////////////////////////////////////////////////*/

        // Run the cancel test.
        cancel(params);
    }
}
