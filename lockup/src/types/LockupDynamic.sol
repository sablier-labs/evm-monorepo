// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD2x18 } from "@prb/math/src/UD2x18.sol";

/// @notice Namespace for the structs used only in LD streams.
library LockupDynamic {
    /// @notice Segment struct stored to represent LD streams.
    /// @param amount The amount of tokens streamed in the segment, denoted in units of the token's decimals.
    /// @param exponent The exponent of the segment, denoted as a fixed-point number.
    /// @param timestamp The Unix timestamp indicating the segment's end.
    struct Segment {
        // slot 0
        uint128 amount;
        UD2x18 exponent;
        uint40 timestamp;
    }

    /// @notice Segment struct used at runtime in {SablierLockupDynamic.createWithDurationsLD} function.
    /// @param amount The amount of tokens streamed in the segment, denoted in units of the token's decimals.
    /// @param exponent The exponent of the segment, denoted as a fixed-point number.
    /// @param duration The time difference in seconds between the segment and the previous one.
    struct SegmentWithDuration {
        uint128 amount;
        UD2x18 exponent;
        uint40 duration;
    }
}
