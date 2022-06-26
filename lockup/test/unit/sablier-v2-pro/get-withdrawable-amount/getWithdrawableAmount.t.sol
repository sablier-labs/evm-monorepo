// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { e, SD59x18 } from "@prb/math/SD59x18.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

/// @dev Basic tests found in the SablierV2Linear and SablierV2Cliff contracts.
contract SablierV2Pro__UnitTest__GetWithdrawableAmount__Basics is SablierV2ProUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, all tests need it.
        streamId = createDefaultDaiStream();
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(nonStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the start time is greater than the block timestamp, it should return zero.
    function testGetWithdrawableAmount__StartTimeGreaterThanBlockTimestamp() external {
        vm.warp(daiStream.startTime - 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the start time is equal to the block timestamp, it should return zero.
    function testGetWithdrawableAmount__StartTimeEqualToBlockTimestamp() external {
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external {
        vm.warp(daiStream.stopTime + 1 seconds);
        uint256 withdrawAmount = bn(2_500, 18);
        sablierV2Pro.withdraw(streamId, withdrawAmount);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external {
        vm.warp(daiStream.stopTime + 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external {
        vm.warp(daiStream.stopTime);
        uint256 withdrawAmount = bn(2_500, 18);
        sablierV2Pro.withdraw(streamId, withdrawAmount);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external {
        vm.warp(daiStream.stopTime);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When there have been withdrawals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__WithWithdrawals() external {
        vm.warp(daiStream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 withdrawAmount = bn(5, 18);
        sablierV2Pro.withdraw(streamId, withdrawAmount);
        uint256 expectedWithdrawableAmount = 25.73721928961166e18 - withdrawAmount; // 1st term: ~2,000*0.25^{3.14}
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }
}

/// @dev Wrapper contract for the case when the current time is less than the stop time and when
/// there have been no withdrawals.
contract SablierV2Pro__UnitTest__GetWithdrawableAmount__Segments is SablierV2ProUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, most tests need it.
        streamId = createDefaultDaiStream();
    }

    /// @dev When there haven't been withdrawals, there is one segment and the token has 6 decimals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__OneSegment__6Decimals() external {
        uint256 daiDepositAmount = SEGMENT_AMOUNTS_USDC[0] + SEGMENT_AMOUNTS_USDC[1];
        uint256[] memory segmentAmounts = createDynamicArray(daiDepositAmount);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[1]);
        uint256[] memory segmentMilestones = createDynamicArray(SEGMENT_MILESTONES[1]);

        streamId = sablierV2Pro.create(
            usdcStream.sender,
            usdcStream.recipient,
            daiDepositAmount,
            usdcStream.token,
            usdcStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            usdcStream.cancelable
        );

        vm.warp(usdcStream.startTime + 2_000 seconds); // 2,000 seconds is 20% of the stream duration.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 4472.135955e6; // ~10,000*0.2^{0.5}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When there haven't been withdrawals, there is one segment and the token has 18 decimals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__OneSegment__18Decimals() external {
        uint256 usdcDepositAmount = SEGMENT_AMOUNTS_DAI[0] + SEGMENT_AMOUNTS_DAI[1];
        uint256[] memory segmentAmounts = createDynamicArray(usdcDepositAmount);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[1]);
        uint256[] memory segmentMilestones = createDynamicArray(SEGMENT_MILESTONES[1]);

        streamId = sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            usdcDepositAmount,
            daiStream.token,
            daiStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            daiStream.cancelable
        );

        vm.warp(daiStream.startTime + 2_000 seconds); // 2,000 seconds is 20% of the stream duration.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 4472.13595499957941e18; // ~10,000*0.2^{0.5}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When there are multiple segments, the current milestone is the 1st in the array and the token
    /// has 6 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__1stInArray__6Decimals() external {
        uint256 usdcStreamId = createDefaultUsdcStream();
        vm.warp(usdcStream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
        uint256 expectedWithdrawableAmount = 25.737219e6; // ~2,000*0.25^{3.14}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When there are multiple segments, the current milestone is the 2nd in the array and the token
    /// has 6 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__2ndInArray__6Decimals() external {
        uint256 usdcStreamId = createDefaultUsdcStream();
        vm.warp(usdcStream.startTime + 2_800 seconds); // 2,800 seconds is 10% of the way in the second segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
        // 2nd term: ~8,000*0.1^{0.5}
        uint256 expectedWithdrawableAmount = SEGMENT_AMOUNTS_USDC[0] + 2529.822128e6;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When there are multiple segments, the current milestone is the 200th in the array and the token
    /// has 6 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__200thInArray__6Decimals() external {
        uint256 count = sablierV2Pro.MAX_SEGMENT_COUNT();
        uint256[] memory segmentAmounts = new uint256[](count);
        SD59x18[] memory segmentExponents = new SD59x18[](count);
        uint256[] memory segmentMilestones = new uint256[](count);

        unchecked {
            // Generate 200 segments that each have the same amount, same exponent and are evenly spread apart.
            uint256 segmentAmount = usdcStream.depositAmount / count;
            SD59x18 segmentExponent = e();
            uint256 totalDuration = usdcStream.stopTime - usdcStream.startTime;
            uint256 segmentDuration = totalDuration / count;
            for (uint256 i = 0; i < count; ) {
                segmentAmounts[i] = segmentAmount;
                segmentExponents[i] = segmentExponent;
                segmentMilestones[i] = usdcStream.startTime + segmentDuration * (i + 1);
                i += 1;
            }

            // Create the 200-segment stream.
            uint256 usdcStreamId = sablierV2Pro.create(
                usdcStream.sender,
                usdcStream.recipient,
                usdcStream.depositAmount,
                usdcStream.token,
                usdcStream.startTime,
                segmentAmounts,
                segmentExponents,
                segmentMilestones,
                usdcStream.cancelable
            );
            vm.warp(usdcStream.stopTime - segmentDuration / 2);

            uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
            // 3rd term: 50*0.5^e
            uint256 expectedWithdrawableAmount = segmentAmount * (count - 1) + 7.597761e6;
            assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
        }
    }

    /// @dev When there are multiple segments, the current milestone is the 1st in the array and the token
    /// has 18 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__1stInArray__18Decimals() external {
        vm.warp(daiStream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        uint256 expectedWithdrawableAmount = 25.73721928961166e18; // ~2,000*0.25^{3.14}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When there are multiple segments, the current milestone is the 2nd in the array and the token
    /// has 18 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__2ndInArray__18Decimals() external {
        vm.warp(daiStream.startTime + 2_800 seconds); // 2,800 seconds is 10% of the way in the second segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        // 2nd term: ~8,000*0.1^{0.5}
        uint256 expectedWithdrawableAmount = SEGMENT_AMOUNTS_DAI[0] + 2529.822128134703472e18;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When there are multiple segments, the current milestone is the 200th in the array and the token
    /// has 18 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__200thInArray__18Decimals() external {
        uint256 count = sablierV2Pro.MAX_SEGMENT_COUNT();
        uint256[] memory segmentAmounts = new uint256[](count);
        SD59x18[] memory segmentExponents = new SD59x18[](count);
        uint256[] memory segmentMilestones = new uint256[](count);

        unchecked {
            // Generate 200 segments that each have the same amount, same exponent and are evenly spread apart.
            uint256 segmentAmount = daiStream.depositAmount / count;
            SD59x18 segmentExponent = e();
            uint256 totalDuration = daiStream.stopTime - daiStream.startTime;
            uint256 segmentDuration = totalDuration / count;
            for (uint256 i = 0; i < count; ) {
                segmentAmounts[i] = segmentAmount;
                segmentExponents[i] = segmentExponent;
                segmentMilestones[i] = daiStream.startTime + segmentDuration * (i + 1);
                i += 1;
            }

            // Create the 200-segment stream.
            streamId = sablierV2Pro.create(
                daiStream.sender,
                daiStream.recipient,
                daiStream.depositAmount,
                daiStream.token,
                daiStream.startTime,
                segmentAmounts,
                segmentExponents,
                segmentMilestones,
                daiStream.cancelable
            );
            vm.warp(daiStream.stopTime - segmentDuration / 2);

            uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
            // 3rd term: 50*0.5^e
            uint256 expectedWithdrawableAmount = segmentAmount * (count - 1) + 7.59776116289564825e18;
            assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
        }
    }
}
