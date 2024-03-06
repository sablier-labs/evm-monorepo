// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";

import { Vm } from "@prb/test/src/PRBTest.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { LockupDynamic, LockupTranched } from "../../src/types/DataTypes.sol";

abstract contract Utils is StdUtils, PRBMathUtils {
    /// @dev The virtual address of the Foundry VM.
    address private constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));

    /// @dev An instance of the Foundry VM, which contains cheatcodes for testing.
    Vm private constant vm = Vm(VM_ADDRESS);

    /// @dev Bounds a `uint128` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal pure returns (uint128) {
        return uint128(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Bounds a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal pure returns (uint40) {
        return uint40(_bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Retrieves the current block timestamp as an `uint40`.
    function getBlockTimestamp() internal view returns (uint40) {
        return uint40(block.timestamp);
    }

    /// @dev Turns the segments with durations into canonical segments, which have timestamps.
    function getSegmentsWithTimestamps(LockupDynamic.SegmentWithDuration[] memory segments)
        internal
        view
        returns (LockupDynamic.Segment[] memory segmentsWithTimestamps)
    {
        unchecked {
            segmentsWithTimestamps = new LockupDynamic.Segment[](segments.length);
            segmentsWithTimestamps[0] = LockupDynamic.Segment({
                amount: segments[0].amount,
                exponent: segments[0].exponent,
                timestamp: getBlockTimestamp() + segments[0].duration
            });
            for (uint256 i = 1; i < segments.length; ++i) {
                segmentsWithTimestamps[i] = LockupDynamic.Segment({
                    amount: segments[i].amount,
                    exponent: segments[i].exponent,
                    timestamp: segmentsWithTimestamps[i - 1].timestamp + segments[i].duration
                });
            }
        }
    }

    /// @dev Turns the tranches with durations into canonical tranches, which have timestamps.
    function getTranchesWithTimestamps(LockupTranched.TrancheWithDuration[] memory tranches)
        internal
        view
        returns (LockupTranched.Tranche[] memory tranchesWithTimestamps)
    {
        unchecked {
            tranchesWithTimestamps = new LockupTranched.Tranche[](tranches.length);
            tranchesWithTimestamps[0] = LockupTranched.Tranche({
                amount: tranches[0].amount,
                timestamp: getBlockTimestamp() + tranches[0].duration
            });
            for (uint256 i = 1; i < tranches.length; ++i) {
                tranchesWithTimestamps[i] = LockupTranched.Tranche({
                    amount: tranches[i].amount,
                    timestamp: tranchesWithTimestamps[i - 1].timestamp + tranches[i].duration
                });
            }
        }
    }

    /// @dev Checks if the Foundry profile is "test-optimized".
    function isTestOptimizedProfile() internal returns (bool) {
        string memory profile = vm.envOr({ name: "FOUNDRY_PROFILE", defaultValue: string("default") });
        return Strings.equal(profile, "test-optimized");
    }
}
