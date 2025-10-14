// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Lockup } from "./Lockup.sol";
import { LockupDynamic } from "./LockupDynamic.sol";
import { LockupLinear } from "./LockupLinear.sol";
import { LockupTranched } from "./LockupTranched.sol";

/// @dev Namespace for the structs used in `SablierBatchLockup` contract.
library BatchLockup {
    /// @notice A struct encapsulating all parameters of {SablierLockupDynamic.createWithDurationsLD} except for the
    /// token.
    struct CreateWithDurationsLD {
        address sender;
        address recipient;
        uint128 depositAmount;
        bool cancelable;
        bool transferable;
        LockupDynamic.SegmentWithDuration[] segmentsWithDuration;
        string shape;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupLinear.createWithDurationsLL} except for the
    /// token.
    struct CreateWithDurationsLL {
        address sender;
        address recipient;
        uint128 depositAmount;
        bool cancelable;
        bool transferable;
        LockupLinear.Durations durations;
        LockupLinear.UnlockAmounts unlockAmounts;
        string shape;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupTranched.createWithDurationsLT} except for the
    /// token.
    struct CreateWithDurationsLT {
        address sender;
        address recipient;
        uint128 depositAmount;
        bool cancelable;
        bool transferable;
        LockupTranched.TrancheWithDuration[] tranchesWithDuration;
        string shape;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupDynamic.createWithTimestampsLD} except for the
    /// token.
    struct CreateWithTimestampsLD {
        address sender;
        address recipient;
        uint128 depositAmount;
        bool cancelable;
        bool transferable;
        uint40 startTime;
        LockupDynamic.Segment[] segments;
        string shape;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupLinear.createWithTimestampsLL} except for the
    /// token.
    struct CreateWithTimestampsLL {
        address sender;
        address recipient;
        uint128 depositAmount;
        bool cancelable;
        bool transferable;
        Lockup.Timestamps timestamps;
        uint40 cliffTime;
        LockupLinear.UnlockAmounts unlockAmounts;
        string shape;
    }

    /// @notice A struct encapsulating all parameters of {SablierLockupTranched.createWithTimestampsLT} except for the
    /// token.
    struct CreateWithTimestampsLT {
        address sender;
        address recipient;
        uint128 depositAmount;
        bool cancelable;
        bool transferable;
        uint40 startTime;
        LockupTranched.Tranche[] tranches;
        string shape;
    }
}
