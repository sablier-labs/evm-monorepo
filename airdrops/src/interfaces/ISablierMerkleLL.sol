// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { MerkleLL } from "./../types/DataTypes.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleLL
/// @notice Merkle Lockup enables airdrops with a vesting period powered by the Lockup Linear distribution model.
interface ISablierMerkleLL is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims a stream.
    event Claim(uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the {SablierLockup} contract.
    function LOCKUP() external view returns (ISablierLockup);

    /// @notice A flag indicating whether the streams can be canceled.
    /// @dev This is an immutable state variable.
    function STREAM_CANCELABLE() external returns (bool);

    /// @notice A flag indicating whether the stream NFTs are transferable.
    /// @dev This is an immutable state variable.
    function STREAM_TRANSFERABLE() external returns (bool);

    /// @notice A tuple containing the start time, start unlock amount, cliff duration, cliff unlock amount, and end
    /// duration. These values are used to calculate the vesting schedule in `Lockup.CreateWithTimestampsLL`.
    /// @dev A start time value of zero will be considered as `block.timestamp`.
    function getSchedule() external view returns (MerkleLL.Schedule memory);
}
