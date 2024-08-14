// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockupLinear } from "../../core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../../core/interfaces/ISablierLockupTranched.sol";
import { LockupLinear } from "../../core/types/DataTypes.sol";

import { ISablierMerkleInstant } from "./ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "./ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./ISablierMerkleLT.sol";
import { MerkleBase, MerkleLT } from "../types/DataTypes.sol";

/// @title ISablierMerkleFactory
/// @notice A contract that deploys Merkle Lockups and Merkle Instant campaigns. Both of these use Merkle proofs for
/// token distribution. Merkle Lockup enable Airstreams, a portmanteau of "airdrop" and "stream". This is an airdrop
/// model where the tokens are distributed over time, as opposed to all at once. On the other hand, Merkle Instant
/// enables instant airdrops where tokens are unlocked and distributed immediately. See the Sablier docs for more
/// guidance: https://docs.sablier.com
/// @dev Deploys Merkle Lockup and Merkle Instant campaigns with CREATE2.
interface ISablierMerkleFactory {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleInstant} campaign is created.
    event CreateMerkleInstant(
        ISablierMerkleInstant indexed merkleInstant,
        MerkleBase.ConstructorParams baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    /// @notice Emitted when a {SablierMerkleLL} campaign is created.
    event CreateMerkleLL(
        ISablierMerkleLL indexed merkleLL,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockupLinear lockupLinear,
        bool cancelable,
        bool transferable,
        LockupLinear.Durations streamDurations,
        uint256 aggregateAmount,
        uint256 recipientCount
    );

    /// @notice Emitted when a {SablierMerkleLT} campaign is created.
    event CreateMerkleLT(
        ISablierMerkleLT indexed merkleLT,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockupTranched lockupTranched,
        bool cancelable,
        bool transferable,
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

    /// @notice Creates a new MerkleInstant campaign for instant distribution of assets.
    /// @dev Emits a {CreateMerkleInstant} event.
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleInstant The address of the newly created MerkleInstant contract.
    function createMerkleInstant(
        MerkleBase.ConstructorParams memory baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleInstant merkleInstant);

    /// @notice Creates a new Merkle Lockup campaign with a LockupLinear distribution.
    /// @dev Emits a {CreateMerkleLL} event.
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockupLinear The address of the {SablierLockupLinear} contract.
    /// @param cancelable Indicates if the stream will be cancelable after claiming.
    /// @param transferable Indicates if the stream will be transferable after claiming.
    /// @param streamDurations The durations for each stream.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLL The address of the newly created Merkle Lockup contract.
    function createMerkleLL(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockupLinear lockupLinear,
        bool cancelable,
        bool transferable,
        LockupLinear.Durations memory streamDurations,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLL merkleLL);

    /// @notice Creates a new Merkle Lockup campaign with a LockupTranched distribution.
    /// @dev Emits a {CreateMerkleLT} event.
    ///
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockupTranched The address of the {SablierLockupTranched} contract.
    /// @param cancelable Indicates if the stream will be cancelable after claiming.
    /// @param transferable Indicates if the stream will be transferable after claiming.
    /// @param tranchesWithPercentages The tranches with their respective unlock percentages.
    /// @param aggregateAmount The total amount of ERC-20 assets to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLT The address of the newly created Merkle Lockup contract.
    function createMerkleLT(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockupTranched lockupTranched,
        bool cancelable,
        bool transferable,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLT merkleLT);
}
