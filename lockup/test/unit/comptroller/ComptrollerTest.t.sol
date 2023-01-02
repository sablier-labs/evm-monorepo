// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { UnitTest } from "../UnitTest.t.sol";

/// @title ComptrollerTest
/// @notice Dummy contract only needed to provide naming context in the test suites.
abstract contract ComptrollerTest is UnitTest {
    function setUp() public virtual override {
        super.setUp();
    }

    /// @dev This function must be overridden for the test contracts to compile, but it is not actually used.
    function createDefaultStream() internal pure override returns (uint256 streamId) {
        streamId = 0;
    }

    /// @dev This function must be overridden for the test contracts to compile, but it is not actually used.
    function createDefaultStreamNonCancelable() internal pure override returns (uint256 streamId) {
        streamId = 0;
    }
}
