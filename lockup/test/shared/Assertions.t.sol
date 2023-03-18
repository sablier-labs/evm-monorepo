// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";

import { Lockup, LockupDynamic, LockupLinear } from "../../src/types/DataTypes.sol";

abstract contract Assertions is PRBTest, PRBMathAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event LogNamedArray(string key, LockupDynamic.Segment[] segments);

    event LogNamedUint128(string key, uint128 value);

    event LogNamedUint40(string key, uint40 value);

    /*//////////////////////////////////////////////////////////////////////////
                                     ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Compares two `Lockup.Amounts` struct entities.
    function assertEq(Lockup.Amounts memory a, Lockup.Amounts memory b) internal {
        assertEqUint128(a.deposit, b.deposit, "amounts.deposit");
        assertEqUint128(a.withdrawn, b.withdrawn, "amounts.withdrawn");
    }

    /// @dev Compares two `IERC20` addresses.
    function assertEq(IERC20 a, IERC20 b) internal {
        assertEq(address(a), address(b));
    }

    /// @dev Compares two `IERC20` addresses.
    function assertEq(IERC20 a, IERC20 b, string memory err) internal {
        assertEq(address(a), address(b), err);
    }

    /// @dev Compares two `LockupLinear.Stream` struct entities.
    function assertEq(LockupLinear.Stream memory a, LockupLinear.Stream memory b) internal {
        assertEq(a.amounts, b.amounts);
        assertEq(a.cliffTime, b.cliffTime, "cliffTime");
        assertEq(a.endTime, b.endTime, "endTime");
        assertEq(a.isCancelable, b.isCancelable, "isCancelable");
        assertEq(a.sender, b.sender, "sender");
        assertEq(a.status, b.status);
        assertEq(a.startTime, b.startTime, "startTime");
        assertEq(a.asset, b.asset, "asset");
    }

    /// @dev Compares two `LockupDynamic.Stream` struct entities.
    function assertEq(LockupDynamic.Stream memory a, LockupDynamic.Stream memory b) internal {
        assertEq(a.endTime, b.endTime, "endTime");
        assertEq(a.isCancelable, b.isCancelable, "isCancelable");
        assertEq(a.segments, b.segments, "segments");
        assertEq(a.sender, b.sender, "sender");
        assertEq(a.startTime, b.startTime, "startTime");
        assertEq(a.status, b.status);
        assertEq(a.asset, b.asset, "asset");
    }

    /// @dev Compares two `LockupLinear.Range` struct entities.
    function assertEq(LockupLinear.Range memory a, LockupLinear.Range memory b) internal {
        assertEqUint40(a.cliff, b.cliff, "range.cliff");
        assertEqUint40(a.end, b.end, "range.end");
        assertEqUint40(a.start, b.start, "range.start");
    }

    /// @dev Compares two `LockupDynamic.Range` struct entities.
    function assertEq(LockupDynamic.Range memory a, LockupDynamic.Range memory b) internal {
        assertEqUint40(a.end, b.end, "range.end");
        assertEqUint40(a.start, b.start, "range.start");
    }

    /// @dev Compares two `Segment[]` arrays.
    function assertEq(LockupDynamic.Segment[] memory a, LockupDynamic.Segment[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [LockupDynamic.Segment[]]");
            emit LogNamedArray("   Left", b);
            emit LogNamedArray("  Right", a);
            fail();
        }
    }

    /// @dev Compares two `LockupDynamic.Segment[]` arrays.
    function assertEq(LockupDynamic.Segment[] memory a, LockupDynamic.Segment[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Compares two `Lockup.Status` enum values.
    function assertEq(Lockup.Status a, Lockup.Status b) internal {
        assertEq(uint8(a), uint8(b), "status");
    }

    /// @dev Compares two `Lockup.Status` enum values.
    function assertEq(Lockup.Status a, Lockup.Status b, string memory err) internal {
        assertEq(uint8(a), uint8(b), err);
    }

    /// @dev Compares two `uint128` numbers.
    function assertEqUint128(uint128 a, uint128 b) internal {
        if (a != b) {
            emit Log("Error: a == b not satisfied [uint128]");
            emit LogNamedUint128("   Left", b);
            emit LogNamedUint128("  Right", a);
            fail();
        }
    }

    /// @dev Compares two `uint128` numbers.
    function assertEqUint128(uint128 a, uint128 b, string memory err) internal {
        if (a != b) {
            emit LogNamedString("Error", err);
            assertEqUint128(a, b);
        }
    }

    /// @dev Compares two `uint40` numbers.
    function assertEqUint40(uint40 a, uint40 b) internal {
        if (a != b) {
            emit Log("Error: a == b not satisfied [uint40]");
            emit LogNamedUint40("   Left", b);
            emit LogNamedUint40("  Right", a);
            fail();
        }
    }

    /// @dev Compares two `uint40` numbers.
    function assertEqUint40(uint40 a, uint40 b, string memory err) internal {
        if (a != b) {
            emit LogNamedString("Error", err);
            assertEqUint40(a, b);
        }
    }
}
