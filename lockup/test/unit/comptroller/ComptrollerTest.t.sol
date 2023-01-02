// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { UnitTest } from "../UnitTest.t.sol";

/// @title ComptrollerTest
/// @notice Boilerplate contract needed to compile the test contracts.
abstract contract ComptrollerTest is UnitTest {
    function setUp() public virtual override {
        UnitTest.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                               COMPILER BOILERPLATE
    //////////////////////////////////////////////////////////////////////////*/

    function assertDeleted(uint256 streamId) internal pure override {
        streamId;
    }

    function assertDeleted(uint256[] memory streamIds) internal pure override {
        streamIds;
    }

    function createDefaultStream() internal pure override returns (uint256 streamId) {
        streamId = 0;
    }

    function createDefaultStreamNonCancelable() internal pure override returns (uint256 streamId) {
        streamId = 0;
    }

    function createDefaultStreamWithRecipient(address recipient) internal pure override returns (uint256 streamId) {
        recipient;
        streamId = 0;
    }

    function createDefaultStreamWithSender(address sender) internal pure override returns (uint256 streamId) {
        sender;
        streamId = 0;
    }

    function createDefaultStreamWithStopTime(uint40 stopTime) internal pure override returns (uint256 streamId) {
        stopTime;
        streamId = 0;
    }
}
