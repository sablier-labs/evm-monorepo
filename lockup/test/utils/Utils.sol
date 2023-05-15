// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { PRBMathUtils } from "@prb/math/test/Utils.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import { LockupDynamic } from "../../src/types/DataTypes.sol";

abstract contract Utils is StdUtils, PRBMathUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                       BOUND
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Bounds a `uint128` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal pure returns (uint128 result) {
        result = uint128(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Bounds a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal pure returns (uint40 result) {
        result = uint40(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       TYPES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }

    /// @dev Turns the segments with deltas into canonical segments, which have milestones.
    function getSegmentsWithMilestones(LockupDynamic.SegmentWithDelta[] memory segments)
        internal
        view
        returns (LockupDynamic.Segment[] memory segmentsWithMilestones)
    {
        unchecked {
            segmentsWithMilestones = new LockupDynamic.Segment[](segments.length);
            segmentsWithMilestones[0] = LockupDynamic.Segment({
                amount: segments[0].amount,
                exponent: segments[0].exponent,
                milestone: getBlockTimestamp() + segments[0].delta
            });
            for (uint256 i = 1; i < segments.length; ++i) {
                segmentsWithMilestones[i] = LockupDynamic.Segment({
                    amount: segments[i].amount,
                    exponent: segments[i].exponent,
                    milestone: segmentsWithMilestones[i - 1].milestone + segments[i].delta
                });
            }
        }
    }
}
