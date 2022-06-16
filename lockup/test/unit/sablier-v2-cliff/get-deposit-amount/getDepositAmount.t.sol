// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__GetDepositAmount is SablierV2CliffUnitTest {
    /// @dev When the stream does not exist, it should return zero.
    function testGetDepositAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualDepositAmount = sablierV2Cliff.getDepositAmount(nonStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev When the stream exists, it should the correct deposit amount.
    function testGetDepositAmount() external {
        uint256 streamId = createDefaultStream();
        uint256 actualDepositAmount = sablierV2Cliff.getDepositAmount(streamId);
        uint256 expectedDepositAmount = stream.depositAmount;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
