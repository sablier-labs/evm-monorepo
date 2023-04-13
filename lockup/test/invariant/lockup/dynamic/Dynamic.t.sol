// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2LockupDynamic } from "src/SablierV2LockupDynamic.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Lockup_Invariant_Test } from "../Lockup.t.sol";
import { LockupDynamicCreateHandler } from "../../handlers/LockupDynamicCreateHandler.t.sol";
import { LockupDynamicHandler } from "../../handlers/LockupDynamicHandler.t.sol";

/// @title Dynamic_Invariant_Test
/// @dev Invariant tests for for {SablierV2LockupDynamic}.
contract Dynamic_Invariant_Test is Lockup_Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupDynamicHandler internal dynamicHandler;
    LockupDynamicCreateHandler internal dynamicCreateHandler;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Invariant_Test.setUp();

        // Deploy the dynamic contract handlers.
        dynamicHandler = new LockupDynamicHandler({
            asset_: DEFAULT_ASSET,
            dynamic_: dynamic,
            store_: lockupHandlerStorage
        });
        dynamicCreateHandler = new LockupDynamicCreateHandler({
            asset_: DEFAULT_ASSET,
            comptroller_: comptroller,
            dynamic_: dynamic,
            store_: lockupHandlerStorage
        });

        // Cast the dynamic contract as {SablierV2Lockup} and the dynamic handler as {LockupHandler}.
        lockup = dynamic;
        lockupHandler = dynamicHandler;

        // Target the dynamic handlers for invariant testing.
        targetContract(address(dynamicHandler));
        targetContract(address(dynamicCreateHandler));

        // Exclude the dynamic handlers from being `msg.sender`.
        excludeSender(address(dynamicHandler));
        excludeSender(address(dynamicCreateHandler));

        // Label the handler contracts.
        vm.label({ account: address(dynamicHandler), newLabel: "LockupDynamicHandler" });
        vm.label({ account: address(dynamicCreateHandler), newLabel: "LockupDynamicCreateHandler" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The deposited amount must not be zero.
    function invariant_DepositedAmountNotZero() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupDynamic.Stream memory stream = dynamic.getStream(streamId);
            assertNotEq(stream.amounts.deposited, 0, "Invariant violated: stream non-null, deposited amount zero");
        }
    }

    /// @dev The end time cannot be zero because it must be greater than the start time (which can be zero).
    function invariant_EndTimeNotZero() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupDynamic.Stream memory stream = dynamic.getStream(streamId);
            assertNotEq(stream.endTime, 0, "Invariant violated: end time zero");
        }
    }

    /// @dev Unordered segment milestones are not allowed.
    function invariant_SegmentMilestonesOrdered() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupDynamic.Segment[] memory segments = dynamic.getSegments(streamId);
            uint40 previousMilestone = segments[0].milestone;
            for (uint256 j = 1; j < segments.length; ++j) {
                assertGt(segments[j].milestone, previousMilestone, "Invariant violated: segment milestones not ordered");
                previousMilestone = segments[j].milestone;
            }
        }
    }
}
