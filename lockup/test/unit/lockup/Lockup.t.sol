// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Unit_Test } from "../Unit.t.sol";

/// @title Lockup_Test
/// @notice Common testing logic needed across {SablierV2Lockup} unit tests.
abstract contract Lockup_Test is Unit_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  CREATE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream but make it non-cancelable.
    function createDefaultStreamNonCancelable() internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal virtual returns (uint256 streamId);

    /// @dev Creates the default stream with the provided stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal virtual returns (uint256 streamId);
}
