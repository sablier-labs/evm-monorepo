// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";
import { CommonBase } from "forge-std/src/Base.sol";
import { SafeCastLib } from "solady/src/utils/SafeCastLib.sol";

import { Helpers } from "src/libraries/Helpers.sol";

import { Constants } from "./Constants.sol";

abstract contract Utils is CommonBase, Constants, PRBMathUtils {
    using SafeCastLib for uint256;

    /// @dev Bounds the rate per second between a realistic range.
    function boundRatePerSecond(uint128 ratePerSecond) internal pure returns (uint128) {
        return boundUint128(ratePerSecond, 0.00001e18, 10e18);
    }

    /// @dev Bound transfer amount to avoid overflow.
    function boundTransferAmount(
        uint128 amount,
        uint128 balance,
        uint8 decimals
    )
        internal
        pure
        returns (uint128 transferAmount)
    {
        uint128 maxDeposit = (UINT128_MAX - balance) / uint128(10 ** (18 - decimals));
        transferAmount = boundUint128(amount, 1, maxDeposit - 1);
    }

    /// @dev Bounds a `uint128` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal pure returns (uint128) {
        return uint128(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Bounds a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal pure returns (uint40) {
        return uint40(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Bounds a `uint8` number.
    function boundUint8(uint8 x, uint8 min, uint8 max) internal pure returns (uint8) {
        return uint8(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(block.timestamp);
    }

    /// @dev Calculates the transfer amount using `TRANSFER_VALUE` and `decimals`.
    function getDefaultTransferAmount(uint8 decimals) internal pure returns (uint128 transferAmount) {
        return TRANSFER_VALUE * (10 ** decimals).toUint128();
    }

    /// @dev Mirror function for {Helpers.calculateNormalizedAmount}.
    function getNormalizedAmount(uint128 amount, uint8 decimals) internal pure returns (uint128) {
        return Helpers.calculateNormalizedAmount(amount, decimals);
    }

    /// @dev Mirror function for {Helpers.calculateTransferAmount}.
    function getTransferAmount(uint128 amount, uint8 decimals) internal pure returns (uint128) {
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
