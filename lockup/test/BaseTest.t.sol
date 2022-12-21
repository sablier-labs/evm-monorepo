// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBMathUtils } from "@prb/math/test/Utils.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";

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

    uint40 internal constant UINT40_MAX = type(uint40).max;
    uint128 internal constant UINT128_MAX = type(uint128).max;
    uint256 internal constant UINT256_MAX = type(uint256).max;

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to compare two `LinearStream` structs.
    function assertEq(DataTypes.LinearStream memory a, DataTypes.LinearStream memory b) internal {
        assertEq(a.cancelable, b.cancelable);
        assertEq(uint256(a.cliffTime), uint256(b.cliffTime));
        assertEq(uint256(a.depositAmount), uint256(b.depositAmount));
        assertEq(a.isEntity, b.isEntity);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEq(a.token, b.token);
        assertEq(uint256(a.withdrawnAmount), uint256(b.withdrawnAmount));
    }

    /// @dev Helper function to compare two `ProStream` structs.
    function assertEq(DataTypes.ProStream memory a, DataTypes.ProStream memory b) internal {
        assertEq(a.cancelable, b.cancelable);
        assertEq(uint256(a.depositAmount), uint256(b.depositAmount));
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

    /// @dev Helper function to compare two `uint40` arrays.
    function assertEqUint40Array(uint40[] memory a, uint40[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint40[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
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

    /// @dev Helper function to bound a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal view returns (uint40 result) {
        result = uint40(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Helper function to create a dynamical `SD1x18` array with 1 element.
    function createDynamicArray(SD1x18 element0) internal pure returns (SD1x18[] memory dynamicalArray) {
        dynamicalArray = new SD1x18[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `SD1x18` array with 2 elements.
    function createDynamicArray(
        SD1x18 element0,
        SD1x18 element1
    ) internal pure returns (SD1x18[] memory dynamicalArray) {
        dynamicalArray = new SD1x18[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `SD1x18` array with 3 elements.
    function createDynamicArray(
        SD1x18 element0,
        SD1x18 element1,
        SD1x18 element2
    ) internal pure returns (SD1x18[] memory dynamicalArray) {
        dynamicalArray = new SD1x18[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Helper function to create a dynamical `uint256` array with 1 element.
    function createDynamicArray(uint256 element0) internal pure returns (uint256[] memory dynamicalArray) {
        dynamicalArray = new uint256[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `uint256` array with 2 elements.
    function createDynamicArray(
        uint256 element0,
        uint256 element1
    ) internal pure returns (uint256[] memory dynamicalArray) {
        dynamicalArray = new uint256[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `uint256` array with 3 elements.
    function createDynamicArray(
        uint256 element0,
        uint256 element1,
        uint256 element2
    ) internal pure returns (uint256[] memory dynamicalArray) {
        dynamicalArray = new uint256[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Helper function to create a dynamical `uint40` array with 1 element.
    function createDynamicUint40Array(uint40 element0) internal pure returns (uint40[] memory dynamicalArray) {
        dynamicalArray = new uint40[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `uint40` array with 2 elements.
    function createDynamicUint40Array(
        uint40 element0,
        uint40 element1
    ) internal pure returns (uint40[] memory dynamicalArray) {
        dynamicalArray = new uint40[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `uint40` array with 3 elements.
    function createDynamicUint40Array(
        uint40 element0,
        uint40 element1,
        uint40 element2
    ) internal pure returns (uint40[] memory dynamicalArray) {
        dynamicalArray = new uint40[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Helper function to create a dynamical `uint128` array with 1 element.
    function createDynamicUint128Array(uint128 element0) internal pure returns (uint128[] memory dynamicalArray) {
        dynamicalArray = new uint128[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `uint128` array with 2 elements.
    function createDynamicUint128Array(
        uint128 element0,
        uint128 element1
    ) internal pure returns (uint128[] memory dynamicalArray) {
        dynamicalArray = new uint128[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `uint128` array with 3 elements.
    function createDynamicUint128Array(
        uint128 element0,
        uint128 element1,
        uint128 element2
    ) internal pure returns (uint128[] memory dynamicalArray) {
        dynamicalArray = new uint128[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Helper function to retrieve the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40 blockTimestamp) {
        blockTimestamp = uint40(block.timestamp);
    }
}
