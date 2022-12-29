// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBMathUtils } from "@prb/math/test/Utils.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import { DataTypes } from "src/types/DataTypes.sol";

abstract contract BaseTest is PRBTest, StdCheats, StdUtils, PRBMathAssertions, PRBMathUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event LogNamedArray(string key, SD1x18[] value);

    event LogNamedArray(string key, uint40[] value);

    event LogNamedArray(string key, uint128[] value);

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal constant DEFAULT_CLIFF_DURATION = 2_500 seconds;
    uint128 internal constant DEFAULT_GROSS_DEPOSIT_AMOUNT = 10_040.160642570281124497e18; // net deposit / (1 - fee)
    uint128 internal constant DEFAULT_NET_DEPOSIT_AMOUNT = 10_000e18;
    UD60x18 internal constant DEFAULT_OPERATOR_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 internal constant DEFAULT_OPERATOR_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of gross deposit
    UD60x18 internal constant DEFAULT_PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    uint128 internal constant DEFAULT_PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of gross deposit
    uint128[] internal DEFAULT_SEGMENT_AMOUNTS = [2_500e18, 7_500e18];
    uint40[] internal DEFAULT_SEGMENT_DELTAS = [2_500 seconds, 7_500 seconds];
    SD1x18[] internal DEFAULT_SEGMENT_EXPONENTS = [SD1x18.wrap(3.14e18), SD1x18.wrap(0.5e18)];
    uint40 internal constant DEFAULT_TIME_WARP = 2_600 seconds;
    uint40 internal constant DEFAULT_TOTAL_DURATION = 10_000 seconds;
    uint128 internal constant DEFAULT_WITHDRAW_AMOUNT = 2_600e18;
    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.1e18); // 10%
    uint256 internal constant MAX_SEGMENT_COUNT = 200;
    uint40 internal constant UINT40_MAX = type(uint40).max;
    uint128 internal constant UINT128_MAX = type(uint128).max;
    uint256 internal constant UINT256_MAX = type(uint256).max;

    /*//////////////////////////////////////////////////////////////////////////
                                     IMMUTABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal immutable DEFAULT_CLIFF_TIME;
    uint40[] internal DEFAULT_SEGMENT_MILESTONES;
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal immutable DEFAULT_STOP_TIME;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_START_TIME = getBlockTimestamp();
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_STOP_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;
        DEFAULT_SEGMENT_MILESTONES = [
            DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION,
            DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
        ];
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to bound a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal view returns (uint40 result) {
        result = uint40(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Helper function to bound a `uint40` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal view returns (uint128 result) {
        result = uint128(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Calculates the protocol fee amount, the operator fee amount, and the net deposit amount.
    function calculateFeeAmounts(
        uint128 grossDepositAmount,
        UD60x18 protocolFee,
        UD60x18 operatorFee
    ) internal pure returns (uint128 protocolFeeAmount, uint128 operatorFeeAmount, uint128 netDepositAmount) {
        protocolFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(protocolFee)));
        operatorFeeAmount = uint128(UD60x18.unwrap(ud(grossDepositAmount).mul(operatorFee)));
        netDepositAmount = grossDepositAmount - protocolFeeAmount - operatorFeeAmount;
    }

    /// @dev Helper function to retrieve the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }

    /// @dev Calculate the segment amounts as two fractions of the provided net deposit amount, one 20%, the other 80%.
    function calculateSegmentAmounts(uint128 netDepositAmount) internal pure returns (uint128[] memory segmentAmounts) {
        segmentAmounts = new uint128[](2);
        segmentAmounts[0] = uint128(UD60x18.unwrap(ud(netDepositAmount).mul(ud(0.2e18))));
        segmentAmounts[1] = netDepositAmount - segmentAmounts[0];
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to compare two `LinearStream` structs.
    function assertEq(DataTypes.LinearStream memory a, DataTypes.LinearStream memory b) internal {
        assertEq(uint256(a.cliffTime), uint256(b.cliffTime));
        assertEq(uint256(a.depositAmount), uint256(b.depositAmount));
        assertEq(a.isCancelable, b.isCancelable);
        assertEq(a.isEntity, b.isEntity);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEq(a.token, b.token);
        assertEq(uint256(a.withdrawnAmount), uint256(b.withdrawnAmount));
    }

    /// @dev Helper function to compare two `ProStream` structs.
    function assertEq(DataTypes.ProStream memory a, DataTypes.ProStream memory b) internal {
        assertEq(uint256(a.depositAmount), uint256(b.depositAmount));
        assertEq(a.isCancelable, b.isCancelable);
        assertEq(a.isEntity, b.isEntity);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEqUint128Array(a.segmentAmounts, b.segmentAmounts);
        assertEq(a.segmentExponents, b.segmentExponents);
        assertEqUint40Array(a.segmentMilestones, b.segmentMilestones);
        assertEq(a.token, b.token);
        assertEq(uint256(a.withdrawnAmount), uint256(b.withdrawnAmount));
    }

    /// @dev Helper function to compare two `uint128` arrays.
    function assertEqUint128Array(uint128[] memory a, uint128[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint128[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }

    /// @dev Helper function to compare two `uint40` arrays.
    function assertEqUint40Array(uint40[] memory a, uint40[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint40[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }
}
