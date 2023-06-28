// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Lockup_Invariant_Test } from "./Lockup.t.sol";
import { LockupLinearHandler } from "./handlers/LockupLinearHandler.sol";
import { LockupLinearCreateHandler } from "./handlers/LockupLinearCreateHandler.sol";

/// @dev Invariant tests for {SablierV2LockupLinear}.
contract LockupLinear_Invariant_Test is Lockup_Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupLinearHandler internal lockupLinearHandler;
    LockupLinearCreateHandler internal lockupLinearCreateHandler;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Invariant_Test.setUp();

        // Deploy the lockupLinear contract handlers.
        lockupLinearHandler = new LockupLinearHandler({
            asset_: dai,
            timestampStore_: timestampStore,
            lockupStore_: lockupStore,
            lockupLinear_: lockupLinear
        });
        lockupLinearCreateHandler = new LockupLinearCreateHandler({
            asset_: dai,
            timestampStore_: timestampStore,
            lockupStore_: lockupStore,
            lockupLinear_: lockupLinear
        });

        // Label the handler contracts.
        vm.label({ account: address(lockupLinearHandler), newLabel: "LockupLinearHandler" });
        vm.label({ account: address(lockupLinearCreateHandler), newLabel: "LockupLinearCreateHandler" });

        // Cast the lockupLinear contract as {ISablierV2Lockup} and the lockupLinear handler as {LockupHandler}.
        lockup = lockupLinear;
        lockupHandler = lockupLinearHandler;

        // Target the lockupLinear handlers for invariant testing.
        targetContract(address(lockupLinearHandler));
        targetContract(address(lockupLinearCreateHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(lockupLinearHandler));
        excludeSender(address(lockupLinearCreateHandler));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The cliff time must not be less than the start time.
    function invariant_CliffTimeGteStartTime() external useCurrentTimestamp {
        uint256 lastStreamId = lockupStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupStore.streamIds(i);
            assertGte(
                lockupLinear.getCliffTime(streamId),
                lockupLinear.getStartTime(streamId),
                "Invariant violated: cliff time < start time"
            );
        }
    }

    /// @dev The deposited amount must not be zero.
    function invariant_DepositedAmountNotZero() external useCurrentTimestamp {
        uint256 lastStreamId = lockupStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupStore.streamIds(i);
            LockupLinear.Stream memory stream = lockupLinear.getStream(streamId);
            assertNotEq(stream.amounts.deposited, 0, "Invariant violated: stream non-null, deposited amount zero");
        }
    }

    /// @dev The end time must not be less than or equal to the cliff time.
    function invariant_EndTimeGtCliffTime() external useCurrentTimestamp {
        uint256 lastStreamId = lockupStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupStore.streamIds(i);
            assertGt(
                lockupLinear.getEndTime(streamId),
                lockupLinear.getCliffTime(streamId),
                "Invariant violated: end time <= cliff time"
            );
        }
    }

    /// @dev The end time must not be zero because it must be greater than the start time (which can be zero).
    function invariant_EndTimeNotZero() external useCurrentTimestamp {
        uint256 lastStreamId = lockupStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupStore.streamIds(i);
            LockupLinear.Stream memory stream = lockupLinear.getStream(streamId);
            assertNotEq(stream.endTime, 0, "Invariant violated: stream non-null, end time zero");
        }
    }

    /// @dev Settled streams must not appear as cancelable in {SablierV2LockupLinear.getStream}.
    function invariant_StatusSettled_GetStream() external {
        uint256 lastStreamId = lockupStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupStore.streamIds(i);
            if (lockupLinear.statusOf(streamId) == Lockup.Status.SETTLED) {
                assertFalse(
                    lockupLinear.getStream(streamId).isCancelable,
                    "Invariant violation: stream returned by getStream() is cancelable"
                );
            }
        }
    }
}
