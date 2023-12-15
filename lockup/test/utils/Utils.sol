// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";

import { Vm } from "@prb/test/src/PRBTest.sol";
import { StdUtils } from "forge-std/src/StdUtils.sol";

import { LockupDynamic } from "../../src/types/DataTypes.sol";

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

    /// @dev Turns the segments with deltas into canonical segments, which have milestones.
    function getSegmentsWithMilestones(LockupDynamic.SegmentWithDelta[] memory segments)
        internal
        view
        returns (LockupDynamic.Segment[] memory segmentsWithMilestones)
    {
        unchecked {
            segmentsWithMilestones = new LockupDynamic.Segment[](segments.length);
            segmentsWithMilestones[0] = LockupDynamic.Segment({
                amount: segments[0].amount,
                exponent: segments[0].exponent,
                milestone: getBlockTimestamp() + segments[0].delta
            });
            for (uint256 i = 1; i < segments.length; ++i) {
                segmentsWithMilestones[i] = LockupDynamic.Segment({
                    amount: segments[i].amount,
                    exponent: segments[i].exponent,
                    milestone: segmentsWithMilestones[i - 1].milestone + segments[i].delta
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
