// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { E, SD59x18 } from "@prb/math/SD59x18.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__GetWithdrawableAmount is SablierV2ProUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default dai stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(nonStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StartTimeGreaterThanBlockTimestamp() external StreamExistent {
        vm.warp(daiStream.startTime - 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StartTimeEqualToBlockTimestamp() external StreamExistent {
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external StreamExistent {
        vm.warp(daiStream.stopTime + 1 seconds);
        uint256 withdrawAmount = 2_500e18;
        sablierV2Pro.withdraw(daiStreamId, withdrawAmount);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external StreamExistent {
        vm.warp(daiStream.stopTime + 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external StreamExistent {
        vm.warp(daiStream.stopTime);
        uint256 withdrawAmount = 2_500e18;
        sablierV2Pro.withdraw(daiStreamId, withdrawAmount);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external StreamExistent {
        vm.warp(daiStream.stopTime);
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CurrentTimeLessThanStopTime() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__WithWithdrawals() external StreamExistent CurrentTimeLessThanStopTime {
        vm.warp(daiStream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 withdrawAmount = 5e18;
        sablierV2Pro.withdraw(daiStreamId, withdrawAmount);
        uint256 expectedWithdrawableAmount = 25.73721928961166e18 - withdrawAmount; // 1st term: ~2,000*0.25^{3.14}
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    modifier NoWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__OneSegment__Token6Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        uint256 usdcDepositAmount = SEGMENT_AMOUNTS_USDC[0] + SEGMENT_AMOUNTS_USDC[1];
        uint256[] memory segmentAmounts = createDynamicArray(usdcDepositAmount);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[1]);
        uint64[] memory segmentMilestones = createDynamicUint64Array(SEGMENT_MILESTONES[1]);

        daiStreamId = sablierV2Pro.create(
            usdcStream.sender,
            users.recipient,
            usdcDepositAmount,
            usdcStream.token,
            usdcStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            usdcStream.cancelable
        );

        vm.warp(usdcStream.startTime + 2_000 seconds); // 2,000 seconds is 20% of the stream duration.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 4472.135955e6; // ~10,000*0.2^{0.5}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__OneSegment__Token18Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        uint256 daiDepositAmount = SEGMENT_AMOUNTS_DAI[0] + SEGMENT_AMOUNTS_DAI[1];
        uint256[] memory segmentAmounts = createDynamicArray(daiDepositAmount);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[1]);
        uint64[] memory segmentMilestones = createDynamicUint64Array(SEGMENT_MILESTONES[1]);

        daiStreamId = sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
            daiDepositAmount,
            daiStream.token,
            daiStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            daiStream.cancelable
        );

        vm.warp(daiStream.startTime + 2_000 seconds); // 2,000 seconds is 20% of the stream duration.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 4472.13595499957941e18; // ~10,000*0.2^{0.5}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone1st__Token6Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        uint256 usdcStreamId = createDefaultUsdcStream();
        vm.warp(usdcStream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
        uint256 expectedWithdrawableAmount = 25.737219e6; // ~2,000*0.25^{3.14}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone1st__Token18Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        vm.warp(daiStream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 25.73721928961166e18; // ~2,000*0.25^{3.14}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone2nd__Token6Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        uint256 usdcStreamId = createDefaultUsdcStream();
        vm.warp(usdcStream.startTime + 2_800 seconds); // 2,800 seconds is 10% of the way in the second segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
        // 2nd term: ~8,000*0.1^{0.5}
        uint256 expectedWithdrawableAmount = SEGMENT_AMOUNTS_USDC[0] + 2529.822128e6;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone2nd__Token18Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        vm.warp(daiStream.startTime + 2_800 seconds); // 2,800 seconds is 10% of the way in the second segment.
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        // 2nd term: ~8,000*0.1^{0.5}
        uint256 expectedWithdrawableAmount = SEGMENT_AMOUNTS_DAI[0] + 2529.822128134703472e18;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone200th__Token6Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        uint256 count = sablierV2Pro.MAX_SEGMENT_COUNT();
        uint256[] memory segmentAmounts = new uint256[](count);
        SD59x18[] memory segmentExponents = new SD59x18[](count);
        uint64[] memory segmentMilestones = new uint64[](count);

        unchecked {
            // Generate 200 segments that each have the same amount, same exponent and are evenly spread apart.
            uint256 segmentAmount = usdcStream.depositAmount / count;
            SD59x18 segmentExponent = E;
            uint64 totalDuration = usdcStream.stopTime - usdcStream.startTime;
            uint64 segmentDuration = totalDuration / uint64(count);
            for (uint256 i = 0; i < count; ) {
                segmentAmounts[i] = segmentAmount;
                segmentExponents[i] = segmentExponent;
                segmentMilestones[i] = usdcStream.startTime + segmentDuration * (uint64(i) + 1);
                i += 1;
            }

            // Create the 200-segment stream.
            uint256 usdcStreamId = sablierV2Pro.create(
                usdcStream.sender,
                users.recipient,
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

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone200th__Token18Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        uint256 count = sablierV2Pro.MAX_SEGMENT_COUNT();
        uint256[] memory segmentAmounts = new uint256[](count);
        SD59x18[] memory segmentExponents = new SD59x18[](count);
        uint64[] memory segmentMilestones = new uint64[](count);

        unchecked {
            // Generate 200 segments that each have the same amount, same exponent and are evenly spread apart.
            uint256 segmentAmount = daiStream.depositAmount / count;
            SD59x18 segmentExponent = E;
            uint64 totalDuration = daiStream.stopTime - daiStream.startTime;
            uint64 segmentDuration = totalDuration / uint64(count);
            for (uint64 i = 0; i < count; ) {
                segmentAmounts[i] = segmentAmount;
                segmentExponents[i] = segmentExponent;
                segmentMilestones[i] = daiStream.startTime + segmentDuration * (i + 1);
                i += 1;
            }

            // Create the 200-segment stream.
            daiStreamId = sablierV2Pro.create(
                daiStream.sender,
                users.recipient,
                daiStream.depositAmount,
                daiStream.token,
                daiStream.startTime,
                segmentAmounts,
                segmentExponents,
                segmentMilestones,
                daiStream.cancelable
            );
            vm.warp(daiStream.stopTime - segmentDuration / 2);

            uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
            // 3rd term: 50*0.5^e
            uint256 expectedWithdrawableAmount = segmentAmount * (count - 1) + 7.59776116289564825e18;
            assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
        }
    }
}
