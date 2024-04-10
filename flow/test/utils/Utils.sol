// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { CommonBase } from "forge-std/src/Base.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

abstract contract Utils is CommonBase, StdUtils {
    /// @dev Stops the active prank and sets a new one.
    function resetPrank(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }
}
