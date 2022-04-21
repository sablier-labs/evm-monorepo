// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__GetWithdrawableAmount__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, all tests need one.
        streamId = createDefaultCliffStream();
    }

    /// @dev When the cliff stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 withdrawableAmount = sablierV2Cliff.getWithdrawableAmount(nonStreamId);
        assertEq(0, withdrawableAmount);
    }

    /* /// @dev When the cliff time is greater than the block timestamp, it should return zero.
    function testGetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp() external {
        vm.warp(cliffStream.cliffTime - 1 seconds);
        uint256 withdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(0, withdrawableAmount);
    }

    /// @dev When the cliff time is equal to the block timestamp
    function testGetWithdrawableAmount__CliffTimeEqualToBlockTimestamp() external {
        vm.warp(cliffStream.startTime + DEFAULT_CLIFF_TIME);
        uint256 expectedWithdrawableAmount = bn(900);
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    } */
}
