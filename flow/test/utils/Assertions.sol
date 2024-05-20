// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OpenEnded } from "src/types/DataTypes.sol";

abstract contract Assertions is StdAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                     ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Compares two {IERC20} values.
    function assertEq(IERC20 a, IERC20 b) internal pure {
        assertEq(address(a), address(b));
    }

    /// @dev Compares two {IERC20} values.
    function assertEq(IERC20 a, IERC20 b, string memory err) internal pure {
        assertEq(address(a), address(b), err);
    }

    /// @dev Compares two {OpenEnded.Stream} struct entities.
    function assertEq(OpenEnded.Stream memory a, OpenEnded.Stream memory b) internal pure {
        assertEq(a.ratePerSecond, b.ratePerSecond, "ratePerSecond");
        assertEq(a.asset, b.asset, "asset");
        assertEq(a.assetDecimals, b.assetDecimals, "assetDecimals");
        assertEq(a.balance, b.balance, "balance");
        assertEq(a.lastTimeUpdate, b.lastTimeUpdate, "lastTimeUpdate");
        assertEq(a.isCanceled, b.isCanceled, "isCanceled");
        assertEq(a.isStream, b.isStream, "isStream");
        assertEq(a.sender, b.sender, "sender");
    }
}
