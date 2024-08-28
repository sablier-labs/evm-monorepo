// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockupLinear } from "../../core/interfaces/ISablierLockupLinear.sol";

import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleLL
/// @notice Merkle Lockup campaign that creates LockupLinear streams.
interface ISablierMerkleLL is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims a stream.
    event Claim(uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A flag indicating whether the streams can be canceled.
    /// @dev This is an immutable state variable.
    function CANCELABLE() external returns (bool);

    /// @notice The address of the {SablierLockupLinear} contract.
    function LOCKUP_LINEAR() external view returns (ISablierLockupLinear);

    /// @notice A flag indicating whether the stream NFTs are transferable.
    /// @dev This is an immutable state variable.
    function TRANSFERABLE() external returns (bool);

    /// @notice The start time, cliff duration and the end duration used to calculate the time variables in
    /// `LockupLinear.CreateWithTimestamps`.
    /// @dev A start time value of zero will be considered as `block.timestamp`.
    function schedule() external view returns (uint40 startTime, uint40 cliffDuration, uint40 endDuration);
}
