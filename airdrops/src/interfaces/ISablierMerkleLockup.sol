// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { ISablierMerkleBase } from "./ISablierMerkleBase.sol";

/// @title ISablierMerkleLockup
/// @dev Common interface between MerkleLL and MerkleLT campaigns.
interface ISablierMerkleLockup is ISablierMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a recipient claims a Lockup stream.
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

    /// @notice Retrieves the stream IDs associated with the airdrops claimed by the provided recipient.
    function claimedStreams(address recipient) external view returns (uint256[] memory);

    /// @notice Retrieves the shape of the lockup stream that the campaign produces upon claiming.
    function shape() external view returns (string memory);
}
