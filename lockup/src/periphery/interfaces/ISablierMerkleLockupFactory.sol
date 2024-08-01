// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockupLinear } from "../../core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../../core/interfaces/ISablierLockupTranched.sol";
import { LockupLinear } from "../../core/types/DataTypes.sol";

import { ISablierMerkleLL } from "./ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./ISablierMerkleLT.sol";
import { MerkleLockup, MerkleLT } from "../types/DataTypes.sol";

/// @title ISablierMerkleLockupFactory
/// @notice Deploys MerkleLockup campaigns with CREATE2.
interface ISablierMerkleLockupFactory {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleLL} campaign is created.
    event CreateMerkleLL(
        ISablierMerkleLL indexed merkleLL,
        MerkleLockup.ConstructorParams baseParams,
        ISablierLockupLinear lockupLinear,
        LockupLinear.Durations streamDurations,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    /// @notice Emitted when a {SablierMerkleLT} campaign is created.
    event CreateMerkleLT(
        ISablierMerkleLT indexed merkleLT,
        MerkleLockup.ConstructorParams baseParams,
        ISablierLockupTranched lockupTranched,
        MerkleLT.TrancheWithPercentage[] tranchesWithPercentages,
        uint256 totalDuration,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Verifies if the sum of percentages in `tranches` equals 100% , i.e. 1e18.
    /// @dev Reverts if the sum of percentages overflows.
    /// @param tranches The tranches with their respective unlock percentages.
    /// @return result True if the sum of percentages equals 100%, otherwise false.
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new MerkleLockup campaign with a LockupLinear distribution.
    /// @dev Emits a {CreateMerkleLL} event.
    /// @param baseParams Struct encapsulating the {SablierMerkleLockup} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockupLinear The address of the {SablierLockupLinear} contract.
    /// @param streamDurations The durations for each stream.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLL The address of the newly created MerkleLockup contract.
    function createMerkleLL(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierLockupLinear lockupLinear,
        LockupLinear.Durations memory streamDurations,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLL merkleLL);

    /// @notice Creates a new MerkleLockup campaign with a LockupTranched distribution.
    /// @dev Emits a {CreateMerkleLT} event.
    ///
    /// @param baseParams Struct encapsulating the {SablierMerkleLockup} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockupTranched The address of the {SablierLockupTranched} contract.
    /// @param tranchesWithPercentages The tranches with their respective unlock percentages.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLT The address of the newly created MerkleLockup contract.
    function createMerkleLT(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierLockupTranched lockupTranched,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLT merkleLT);
}
