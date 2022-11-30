// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { StdCheats, StdUtils } from "forge-std/Components.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";

abstract contract BaseTest is PRBTest, StdCheats, StdUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event LogNamedArray(string key, uint64[] value);

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_SEGMENT_COUNT = 200;
    uint64 internal constant UINT64_MAX = type(uint64).max;
    uint256 internal constant UINT256_MAX = type(uint256).max;

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to compare two `LinearStream` structs.
    function assertEq(DataTypes.LinearStream memory a, DataTypes.LinearStream memory b) internal {
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.cliffTime), uint256(b.cliffTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev Helper function to compare two `ProStream` structs.
    function assertEq(DataTypes.ProStream memory a, DataTypes.ProStream memory b) internal {
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEq(a.segmentAmounts, b.segmentAmounts);
        assertEq(a.segmentExponents, b.segmentExponents);
        assertEqUint64Array(a.segmentMilestones, b.segmentMilestones);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev Helper function to compare two SD59x18 arrays.
    function assertEq(SD59x18[] memory a, SD59x18[] memory b) internal {
        int256[] memory castedA;
        int256[] memory castedB;
        assembly {
            castedA := a
            castedB := b
        }
        assertEq(castedA, castedB);
    }

    /// @dev Helper function to compare two `uint64` arrays.
    function assertEqUint64Array(uint64[] memory a, uint64[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint64[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }

    /// @dev Helper function to create a dynamical `uint256` array with 1 element.
    function createDynamicArray(uint256 element0) internal pure returns (uint256[] memory dynamicalArray) {
        dynamicalArray = new uint256[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `SD59x18` array with 1 element.
    function createDynamicArray(SD59x18 element0) internal pure returns (SD59x18[] memory dynamicalArray) {
        dynamicalArray = new SD59x18[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `uint256` array with 2 elements.
    function createDynamicArray(uint256 element0, uint256 element1)
        internal
        pure
        returns (uint256[] memory dynamicalArray)
    {
        dynamicalArray = new uint256[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `SD59x18` array with 2 elements.
    function createDynamicArray(SD59x18 element0, SD59x18 element1)
        internal
        pure
        returns (SD59x18[] memory dynamicalArray)
    {
        dynamicalArray = new SD59x18[](2);
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

    /// @dev Helper function to create a dynamical `SD59x18` array with 3 elements.
    function createDynamicArray(
        SD59x18 element0,
        SD59x18 element1,
        SD59x18 element2
    ) internal pure returns (SD59x18[] memory dynamicalArray) {
        dynamicalArray = new SD59x18[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }

    /// @dev Helper function to create a dynamical `uint64` array with 1 element.
    function createDynamicUint64Array(uint64 element0) internal pure returns (uint64[] memory dynamicalArray) {
        dynamicalArray = new uint64[](1);
        dynamicalArray[0] = element0;
    }

    /// @dev Helper function to create a dynamical `uint64` array with 2 elements.
    function createDynamicUint64Array(uint64 element0, uint64 element1)
        internal
        pure
        returns (uint64[] memory dynamicalArray)
    {
        dynamicalArray = new uint64[](2);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
    }

    /// @dev Helper function to create a dynamical `uint64` array with 3 elements.
    function createDynamicUint64Array(
        uint64 element0,
        uint64 element1,
        uint64 element2
    ) internal pure returns (uint64[] memory dynamicalArray) {
        dynamicalArray = new uint64[](3);
        dynamicalArray[0] = element0;
        dynamicalArray[1] = element1;
        dynamicalArray[2] = element2;
    }
}
