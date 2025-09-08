// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice Namespace for the structs used only in LT streams.
library LockupTranched {
    /// @notice Tranche struct stored to represent LT streams.
    /// @param amount The amount of tokens to be unlocked in the tranche, denoted in units of the token's decimals.
    /// @param timestamp The Unix timestamp indicating the tranche's end.
    struct Tranche {
        // slot 0
        uint128 amount;
        uint40 timestamp;
    }

    /// @notice Tranche struct used at runtime in {SablierLockupTranched.createWithDurationsLT} function.
    /// @param amount The amount of tokens to be unlocked in the tranche, denoted in units of the token's decimals.
    /// @param duration The time difference in seconds between the tranche and the previous one.
    struct TrancheWithDuration {
        uint128 amount;
        uint40 duration;
    }
}
