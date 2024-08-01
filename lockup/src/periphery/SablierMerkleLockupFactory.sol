// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";

import { ISablierLockupLinear } from "../core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../core/interfaces/ISablierLockupTranched.sol";
import { LockupLinear } from "../core/types/DataTypes.sol";

import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLockupFactory } from "./interfaces/ISablierMerkleLockupFactory.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { SablierMerkleLL } from "./SablierMerkleLL.sol";
import { SablierMerkleLT } from "./SablierMerkleLT.sol";
import { MerkleLockup, MerkleLT } from "./types/DataTypes.sol";

/// @title SablierMerkleLockupFactory
/// @notice See the documentation in {ISablierMerkleLockupFactory}.
contract SablierMerkleLockupFactory is ISablierMerkleLockupFactory {
    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockupFactory
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        override
        returns (bool result)
    {
        uint64 totalPercentage;
        for (uint256 i = 0; i < tranches.length; ++i) {
            totalPercentage += tranches[i].unlockPercentage.unwrap();
        }
        return totalPercentage == uUNIT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice inheritdoc ISablierMerkleLockupFactory
    function createMerkleLL(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierLockupLinear lockupLinear,
        LockupLinear.Durations memory streamDurations,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLL merkleLL)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                baseParams.asset,
                baseParams.cancelable,
                baseParams.expiration,
                baseParams.initialAdmin,
                abi.encode(baseParams.ipfsCID),
                baseParams.merkleRoot,
                bytes32(abi.encodePacked(baseParams.name)),
                baseParams.transferable,
                lockupLinear,
                abi.encode(streamDurations)
            )
        );

        // Deploy the MerkleLockup contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }(baseParams, lockupLinear, streamDurations);

        // Log the creation of the MerkleLockup contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL(merkleLL, baseParams, lockupLinear, streamDurations, aggregateAmount, recipientCount);
    }

    /// @notice inheritdoc ISablierMerkleLockupFactory
    function createMerkleLT(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierLockupTranched lockupTranched,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLT merkleLT)
    {
        uint256 totalDuration;

        // Need a separate scope to prevent the stack too deep error.
        {
            // Calculate the sum of percentages and durations across all tranches.
            uint256 count = tranchesWithPercentages.length;
            for (uint256 i = 0; i < count; ++i) {
                unchecked {
                    // Safe to use `unchecked` because its only used in the event.
                    totalDuration += tranchesWithPercentages[i].duration;
                }
            }
        }

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                baseParams.asset,
                baseParams.cancelable,
                baseParams.expiration,
                baseParams.initialAdmin,
                abi.encode(baseParams.ipfsCID),
                baseParams.merkleRoot,
                bytes32(abi.encodePacked(baseParams.name)),
                baseParams.transferable,
                lockupTranched,
                abi.encode(tranchesWithPercentages)
            )
        );

        // Deploy the MerkleLockup contract with CREATE2.
        merkleLT = new SablierMerkleLT{ salt: salt }(baseParams, lockupTranched, tranchesWithPercentages);

        // Log the creation of the MerkleLockup contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLT(
            merkleLT,
            baseParams,
            lockupTranched,
            tranchesWithPercentages,
            totalDuration,
            aggregateAmount,
            recipientCount
        );
    }
}
