// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";
import { CommonBase } from "forge-std/src/Base.sol";

import { Helpers } from "src/libraries/Helpers.sol";

abstract contract Utils is CommonBase, PRBMathUtils {
    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(block.timestamp);
    }

    function getNormalizedValue(uint128 amount, uint8 decimals) internal pure returns (uint128) {
        return Helpers.calculateNormalizedAmount(amount, decimals);
    }

    function getTransferValue(uint128 amount, uint8 decimals) internal pure returns (uint128) {
        return Helpers.calculateTransferAmount(amount, decimals);
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal view returns (bool) {
        string memory profile = vm.envOr({ name: "FOUNDRY_PROFILE", defaultValue: string("default") });
        return Strings.equal(profile, "test-optimized");
    }

    /// @dev Stops the active prank and sets a new one.
    function resetPrank(address msgSender) internal {
        vm.stopPrank();
        vm.startPrank(msgSender);
    }
}
