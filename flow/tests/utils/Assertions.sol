// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/utils/Assertions.sol";
import { Flow } from "src/types/DataTypes.sol";

abstract contract Assertions is PRBMathAssertions {
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

    /// @dev Compares two {Flow.Stream} struct entities.
    function assertEq(Flow.Stream memory a, Flow.Stream memory b) internal pure {
        assertEq(a.ratePerSecond, b.ratePerSecond, "ratePerSecond");
        assertEq(a.balance, b.balance, "balance");
        assertEq(a.snapshotTime, b.snapshotTime, "snapshotTime");
        assertEq(a.isStream, b.isStream, "isStream");
        assertEq(a.isTransferable, b.isTransferable, "isTransferable");
        assertEq(a.isVoided, b.isVoided, "isVoided");
        assertEq(a.snapshotDebtScaled, b.snapshotDebtScaled, "snapshotDebtScaled");
        assertEq(a.sender, b.sender, "sender");
        assertEq(a.token, b.token, "token");
        assertEq(a.tokenDecimals, b.tokenDecimals, "tokenDecimals");
    }
}
