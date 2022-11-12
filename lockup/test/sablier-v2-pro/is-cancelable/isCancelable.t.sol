// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProBaseTest } from "../SablierV2ProBaseTest.t.sol";

contract IsCancelable__Tests is SablierV2ProBaseTest {
    /// @dev it should return false.
    function testIsCancelable__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        bool actualCancelable = sablierV2Pro.isCancelable(nonStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return true.
    function testIsCancelable__CancelableStream() external StreamExistent {
        uint256 daiStreamId = createDefaultDaiStream();
        bool actualCancelable = sablierV2Pro.isCancelable(daiStreamId);
        bool expectedCancelable = true;
        assertEq(actualCancelable, expectedCancelable);
    }

    modifier NonCancelableStream() {
        _;
    }

    /// @dev it should return false.
    function testIsCancelable() external StreamExistent NonCancelableStream {
        uint256 nonCancelableDaiStreamId = createNonCancelableDaiStream();
        bool actualCancelable = sablierV2Pro.isCancelable(nonCancelableDaiStreamId);
        bool expectedCancelable = false;
        assertEq(actualCancelable, expectedCancelable);
    }
}
