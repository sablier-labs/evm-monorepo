// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";
import { BaseTest as CommonBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupTranched } from "../../src/types/LockupTranched.sol";

abstract contract Utils is CommonBase, PRBMathUtils {
    /// @dev Turns the segments with durations into canonical segments, which have timestamps.
    function getSegmentsWithTimestamps(LockupDynamic.SegmentWithDuration[] memory segments)
        internal
        view
        returns (LockupDynamic.Segment[] memory segmentsWithTimestamps)
    {
        unchecked {
            segmentsWithTimestamps = new LockupDynamic.Segment[](segments.length);
            segmentsWithTimestamps[0] = LockupDynamic.Segment({
                amount: segments[0].amount,
                exponent: segments[0].exponent,
                timestamp: getBlockTimestamp() + segments[0].duration
            });
            for (uint256 i = 1; i < segments.length; ++i) {
                segmentsWithTimestamps[i] = LockupDynamic.Segment({
                    amount: segments[i].amount,
                    exponent: segments[i].exponent,
                    timestamp: segmentsWithTimestamps[i - 1].timestamp + segments[i].duration
                });
            }
        }
    }

    /// @dev Turns the tranches with durations into canonical tranches, which have timestamps.
    function getTranchesWithTimestamps(LockupTranched.TrancheWithDuration[] memory tranches)
        internal
        view
        returns (LockupTranched.Tranche[] memory tranchesWithTimestamps)
    {
        unchecked {
            tranchesWithTimestamps = new LockupTranched.Tranche[](tranches.length);
            tranchesWithTimestamps[0] = LockupTranched.Tranche({
                amount: tranches[0].amount,
                timestamp: getBlockTimestamp() + tranches[0].duration
            });
            for (uint256 i = 1; i < tranches.length; ++i) {
                tranchesWithTimestamps[i] = LockupTranched.Tranche({
                    amount: tranches[i].amount,
                    timestamp: tranchesWithTimestamps[i - 1].timestamp + tranches[i].duration
                });
            }
        }
    }

    /// @dev Returns the largest of the provided `uint40` numbers.
    function maxOfTwo(uint40 a, uint40 b) internal pure returns (uint40) {
        uint40 max = a;
        if (b > max) {
            max = b;
        }
        return max;
    }
}
