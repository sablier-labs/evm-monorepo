// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleLockup
/// @notice MerkleLockup enables Airstreams (a portmanteau of "airdrop" and "stream"), an airdrop model where the
/// tokens are vested over time, as opposed to being unlocked at once. The vesting is provided by Sablier Lockup.
/// @dev Common interface between MerkleLL and MerkleLT.
interface ISablierMerkleLockup is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when `to` receives the airdrop through a direct transfer on behalf of `recipient`.
    event Claim(uint256 index, address indexed recipient, uint128 amount, address to);

    /// @notice Emitted when `to` receives the airdrop through a Lockup stream on behalf of `recipient`.
    event Claim(uint256 index, address indexed recipient, uint128 amount, uint256 indexed streamId, address to);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the {SablierLockup} contract.
    function SABLIER_LOCKUP() external view returns (ISablierLockup);

    /// @notice A flag indicating whether the streams can be canceled.
    /// @dev This is an immutable state variable.
    function STREAM_CANCELABLE() external returns (bool);

    /// @notice A flag indicating whether the stream NFTs are transferable.
    /// @dev This is an immutable state variable.
    function STREAM_TRANSFERABLE() external returns (bool);

    /// @notice Retrieves the stream IDs associated with the airdrops claimed by the provided recipient.
    /// In practice, most campaigns will only have one stream per recipient.
    function claimedStreams(address recipient) external view returns (uint256[] memory);

    /// @notice Retrieves the shape of the Lockup stream created upon claiming.
    function streamShape() external view returns (string memory);
}
