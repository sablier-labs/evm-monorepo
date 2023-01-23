// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";

import { Status } from "src/types/Enums.sol";
import { LockupAmounts, LockupLinearStream, LockupProStream, Range, Segment } from "src/types/Structs.sol";

abstract contract Assertions is PRBTest, PRBMathAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event LogNamedArray(string key, Segment[] segments);

    event LogNamedUint128(string key, uint128 value);

    event LogNamedUint40(string key, uint40 value);

    /*//////////////////////////////////////////////////////////////////////////
                                     ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Compares two `LockupAmounts` struct entities.
    function assertEq(LockupAmounts memory a, LockupAmounts memory b) internal {
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

    /// @dev Compares two `LockupLinearStream` struct entities.
    function assertEq(LockupLinearStream memory a, LockupLinearStream memory b) internal {
        assertEq(a.amounts, b.amounts);
        assertEq(a.isCancelable, b.isCancelable, "isCancelable");
        assertEq(a.sender, b.sender, "sender");
        assertEq(a.status, b.status);
        assertEq(a.range, b.range);
        assertEq(a.asset, b.asset, "asset");
    }

    /// @dev Compares two `LockupProStream` struct entities.
    function assertEq(LockupProStream memory a, LockupProStream memory b) internal {
        assertEq(a.isCancelable, b.isCancelable, "isCancelable");
        assertEq(a.segments, b.segments, "segments");
        assertEq(a.sender, b.sender, "sender");
        assertEq(a.startTime, b.startTime, "startTime");
        assertEq(a.status, b.status);
        assertEq(a.asset, b.asset, "asset");
    }

    /// @dev Compares two `Range` struct entities.
    function assertEq(Range memory a, Range memory b) internal {
        assertEqUint40(a.cliff, b.cliff, "range.cliff");
        assertEqUint40(a.start, b.start, "range.start");
        assertEqUint40(a.stop, b.stop, "range.stop");
    }

    /// @dev Compares two `Segment[]` arrays.
    function assertEq(Segment[] memory a, Segment[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [Segment[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }

    /// @dev Compares two `Segment[]` arrays.
    function assertEq(Segment[] memory a, Segment[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Compares two `Status` enum values.
    function assertEq(Status a, Status b) internal {
        assertEq(uint8(a), uint8(b), "status");
    }

    /// @dev Compares two `Status` enum values.
    function assertEq(Status a, Status b, string memory err) internal {
        assertEq(uint8(a), uint8(b), err);
    }

    /// @dev Compares two `uint128` numbers.
    function assertEqUint128(uint128 a, uint128 b) internal {
        if (a != b) {
            emit Log("Error: a == b not satisfied [uint128]");
            emit LogNamedUint128("  Expected", b);
            emit LogNamedUint128("    Actual", a);
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
            emit LogNamedUint40("  Expected", b);
            emit LogNamedUint40("    Actual", a);
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
