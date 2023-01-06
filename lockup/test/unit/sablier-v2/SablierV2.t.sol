// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { UnitTest } from "../UnitTest.t.sol";

abstract contract SablierV2Test is UnitTest {
    /*//////////////////////////////////////////////////////////////////////////
                                     ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that the given stream was deleted.
    function assertDeleted(uint256 streamId) internal virtual;

    /// @dev Checks that the given streams were deleted.
    function assertDeleted(uint256[] memory streamIds) internal virtual;

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
