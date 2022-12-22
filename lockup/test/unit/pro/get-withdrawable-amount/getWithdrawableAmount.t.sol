// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetWithdrawableAmount__Test is ProTest {
    uint256 internal daiStreamId;
    SD1x18 internal constant E = SD1x18.wrap(2_718281828459045235);

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(nonStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StartTimeGreaterThanBlockTimestamp() external StreamExistent {
        vm.warp({ timestamp: daiStream.startTime - 1 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__StartTimeEqualToBlockTimestamp() external StreamExistent {
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.stopTime + 1 seconds });
        uint128 withdrawAmount = 2_500e18;
        sablierV2Pro.withdraw(daiStreamId, users.recipient, withdrawAmount);
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.stopTime + 1 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.stopTime });
        uint128 withdrawAmount = 2_500e18;
        sablierV2Pro.withdraw(daiStreamId, users.recipient, withdrawAmount);
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.stopTime });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CurrentTimeLessThanStopTime() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__WithWithdrawals() external StreamExistent CurrentTimeLessThanStopTime {
        // 500 seconds is 25% of the way in the first segment.
        vm.warp({ timestamp: daiStream.startTime + 500 seconds });
        uint128 withdrawAmount = 5e18;
        sablierV2Pro.withdraw(daiStreamId, users.recipient, withdrawAmount);
        uint128 expectedWithdrawableAmount = 25.73721928961166e18 - withdrawAmount; // 1st term: ~2,000*0.25^{3.14}
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
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
        uint128 usdcDepositAmount = SEGMENT_AMOUNTS_USDC[0] + SEGMENT_AMOUNTS_USDC[1];
        uint128[] memory segmentAmounts = createDynamicUint128Array(usdcDepositAmount);
        SD1x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[1]);
        uint40[] memory segmentMilestones = createDynamicUint40Array(SEGMENT_MILESTONES[1]);

        uint256 usdcStreamId = sablierV2Pro.create(
            usdcStream.sender,
            users.recipient,
            usdcDepositAmount,
            usdcStream.token,
            usdcStream.cancelable,
            usdcStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones
        );

        // 2,000 seconds is 20% of the stream duration.
        vm.warp({ timestamp: usdcStream.startTime + 2_000 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
        uint128 expectedWithdrawableAmount = 4472.135954e6; // ~10,000*0.2^{0.5}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__OneSegment__Token18Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        uint128 daiDepositAmount = SEGMENT_AMOUNTS_DAI[0] + SEGMENT_AMOUNTS_DAI[1];
        uint128[] memory segmentAmounts = createDynamicUint128Array(daiDepositAmount);
        SD1x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[1]);
        uint40[] memory segmentMilestones = createDynamicUint40Array(SEGMENT_MILESTONES[1]);

        daiStreamId = sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
            daiDepositAmount,
            daiStream.token,
            daiStream.cancelable,
            daiStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones
        );

        // 2,000 seconds is 20% of the stream duration.
        vm.warp({ timestamp: daiStream.startTime + 2_000 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = 4472.13595499957941e18; // ~10,000*0.2^{0.5}
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
        // 500 seconds is 25% of the way in the first segment.
        vm.warp({ timestamp: usdcStream.startTime + 500 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
        uint128 expectedWithdrawableAmount = 25.737219e6; // ~2,000*0.25^{3.14}
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone1st__Token18Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        // 500 seconds is 25% of the way in the first segment.
        vm.warp({ timestamp: daiStream.startTime + 500 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = 25.73721928961166e18; // ~2,000*0.25^{3.14}
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
        // 2,800 seconds is 10% of the way in the second segment.
        vm.warp({ timestamp: usdcStream.startTime + 2_800 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
        // 2nd term: ~8,000*0.1^{0.5}
        uint128 expectedWithdrawableAmount = SEGMENT_AMOUNTS_USDC[0] + 2529.822128e6;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone2nd__Token18Decimals()
        external
        StreamExistent
        CurrentTimeLessThanStopTime
        NoWithdrawals
    {
        // 2,800 seconds is 10% of the way in the second segment.
        vm.warp({ timestamp: daiStream.startTime + 2_800 seconds });
        uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
        // 2nd term: ~8,000*0.1^{0.5}
        uint128 expectedWithdrawableAmount = SEGMENT_AMOUNTS_DAI[0] + 2529.822128134703472e18;
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
        uint128[] memory segmentAmounts = new uint128[](count);
        SD1x18[] memory segmentExponents = new SD1x18[](count);
        uint40[] memory segmentMilestones = new uint40[](count);

        unchecked {
            // Generate 200 segments that each have the same amount, same exponent and are evenly spread apart.
            uint128 segmentAmount = usdcStream.depositAmount / uint128(count);
            SD1x18 segmentExponent = E;
            uint40 totalDuration = usdcStream.stopTime - usdcStream.startTime;
            uint40 segmentDuration = totalDuration / uint40(count);
            for (uint256 i = 0; i < count; ) {
                segmentAmounts[i] = segmentAmount;
                segmentExponents[i] = segmentExponent;
                segmentMilestones[i] = usdcStream.startTime + segmentDuration * (uint40(i) + 1);
                i += 1;
            }

            // Create the 200-segment stream.
            uint256 usdcStreamId = sablierV2Pro.create(
                usdcStream.sender,
                users.recipient,
                usdcStream.depositAmount,
                usdcStream.token,
                usdcStream.cancelable,
                usdcStream.startTime,
                segmentAmounts,
                segmentExponents,
                segmentMilestones
            );
            vm.warp({ timestamp: usdcStream.stopTime - segmentDuration / 2 });

            uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(usdcStreamId);
            // 3rd term: 50*0.5^e
            uint128 expectedWithdrawableAmount = segmentAmount * (uint128(count) - 1) + 7.597761e6;
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
        uint128[] memory segmentAmounts = new uint128[](count);
        SD1x18[] memory segmentExponents = new SD1x18[](count);
        uint40[] memory segmentMilestones = new uint40[](count);

        unchecked {
            // Generate 200 segments that each have the same amount, same exponent and are evenly spread apart.
            uint128 segmentAmount = daiStream.depositAmount / uint128(count);
            SD1x18 segmentExponent = E;
            uint40 totalDuration = daiStream.stopTime - daiStream.startTime;
            uint40 segmentDuration = totalDuration / uint40(count);
            for (uint40 i = 0; i < count; ) {
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
                daiStream.cancelable,
                daiStream.startTime,
                segmentAmounts,
                segmentExponents,
                segmentMilestones
            );
            vm.warp({ timestamp: daiStream.stopTime - segmentDuration / 2 });

            uint128 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(daiStreamId);
            // 3rd term: 50*0.5^e
            uint128 expectedWithdrawableAmount = segmentAmount * (uint128(count) - 1) + 7.59776116289564825e18;
            assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
        }
    }
}
