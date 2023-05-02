// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Lockup_Invariant_Test } from "../lockup/Lockup.t.sol";
import { LockupLinearHandler } from "../handlers/LockupLinearHandler.t.sol";
import { LockupLinearCreateHandler } from "../handlers/LockupLinearCreateHandler.t.sol";

/// @title Linear_Invariant_Test
/// @dev Invariant tests for {SablierV2LockupLinear}.
contract Linear_Invariant_Test is Lockup_Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupLinearHandler internal linearHandler;
    LockupLinearCreateHandler internal linearCreateHandler;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Invariant_Test.setUp();

        // Deploy the linear contract handlers.
        linearHandler = new LockupLinearHandler({
            asset_: usdc,
            linear_: linear,
            store_: lockupHandlerStorage
        });
        linearCreateHandler = new LockupLinearCreateHandler({
            asset_: usdc,
            linear_: linear,
            store_: lockupHandlerStorage
        });

        // Label the handler contracts.
        vm.label({ account: address(linearHandler), newLabel: "LockupLinearHandler" });
        vm.label({ account: address(linearCreateHandler), newLabel: "LockupLinearCreateHandler" });

        // Cast the linear contract as {ISablierV2Lockup} and the linear handler as {LockupHandler}.
        lockup = linear;
        lockupHandler = linearHandler;

        // Target the linear handlers for invariant testing.
        targetContract(address(linearHandler));
        targetContract(address(linearCreateHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(linearHandler));
        excludeSender(address(linearCreateHandler));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The cliff time must not be less than the start time.
    function invariant_CliffTimeGteStartTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                linear.getCliffTime(streamId),
                linear.getStartTime(streamId),
                "Invariant violated: cliff time < start time"
            );
        }
    }

    /// @dev The deposited amount must not be zero.
    function invariant_DepositedAmountNotZero() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupLinear.Stream memory stream = linear.getStream(streamId);
            assertNotEq(stream.amounts.deposited, 0, "Invariant violated: stream non-null, deposited amount zero");
        }
    }

    /// @dev The end time must not be less than or equal to the cliff time.
    function invariant_EndTimeGtCliffTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGt(
                linear.getEndTime(streamId), linear.getCliffTime(streamId), "Invariant violated: end time <= cliff time"
            );
        }
    }

    /// @dev The end time must not be zero because it must be greater than the start time (which can be zero).
    function invariant_EndTimeNotZero() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupLinear.Stream memory stream = linear.getStream(streamId);
            assertNotEq(stream.endTime, 0, "Invariant violated: stream non-null, end time zero");
        }
    }
}
