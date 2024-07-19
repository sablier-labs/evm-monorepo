// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";

import { ISablierV2LockupLinear } from "../core/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupTranched } from "../core/interfaces/ISablierV2LockupTranched.sol";
import { LockupLinear } from "../core/types/DataTypes.sol";

import { ISablierV2MerkleLL } from "./interfaces/ISablierV2MerkleLL.sol";
import { ISablierV2MerkleLockupFactory } from "./interfaces/ISablierV2MerkleLockupFactory.sol";
import { ISablierV2MerkleLT } from "./interfaces/ISablierV2MerkleLT.sol";
import { SablierV2MerkleLL } from "./SablierV2MerkleLL.sol";
import { SablierV2MerkleLT } from "./SablierV2MerkleLT.sol";
import { MerkleLockup, MerkleLT } from "./types/DataTypes.sol";

/// @title SablierV2MerkleLockupFactory
/// @notice See the documentation in {ISablierV2MerkleLockupFactory}.
contract SablierV2MerkleLockupFactory is ISablierV2MerkleLockupFactory {
    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2MerkleLockupFactory
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

    /// @notice inheritdoc ISablierV2MerkleLockupFactory
    function createMerkleLL(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierV2LockupLinear lockupLinear,
        LockupLinear.Durations memory streamDurations,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierV2MerkleLL merkleLL)
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
        merkleLL = new SablierV2MerkleLL{ salt: salt }(baseParams, lockupLinear, streamDurations);

        // Log the creation of the MerkleLockup contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL(merkleLL, baseParams, lockupLinear, streamDurations, aggregateAmount, recipientCount);
    }

    /// @notice inheritdoc ISablierV2MerkleLockupFactory
    function createMerkleLT(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierV2LockupTranched lockupTranched,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierV2MerkleLT merkleLT)
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
        merkleLT = new SablierV2MerkleLT{ salt: salt }(baseParams, lockupTranched, tranchesWithPercentages);

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
