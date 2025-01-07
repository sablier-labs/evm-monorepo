// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAdminable } from "@sablier/lockup/src/interfaces/IAdminable.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";
import { MerkleBase, MerkleFactory, MerkleLL, MerkleLT } from "../types/DataTypes.sol";
import { ISablierMerkleInstant } from "./ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "./ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./ISablierMerkleLT.sol";

/// @title ISablierMerkleFactory
/// @notice A contract that deploys Merkle Lockups and Merkle Instant campaigns. Both use Merkle proofs for token
/// distribution. Merkle Lockup enable Airstreams, a portmanteau of "airdrop" and "stream", an airdrop model where the
/// tokens are distributed over time, as opposed to all at once. On the other hand, Merkle Instant enables instant
/// airdrops where tokens are unlocked and distributed immediately. See the Sablier docs for more guidance:
/// https://docs.sablier.com
/// @dev The contracts are deployed using CREATE2.
interface ISablierMerkleFactory is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the accrued fees are collected.
    event CollectFees(address indexed admin, ISablierMerkleBase indexed merkleBase, uint256 feeAmount);

    /// @notice Emitted when a {SablierMerkleInstant} campaign is created.
    event CreateMerkleInstant(
        ISablierMerkleInstant indexed merkleInstant,
        MerkleBase.ConstructorParams baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount,
        uint256 fee
    );

    /// @notice Emitted when a {SablierMerkleLL} campaign is created.
    event CreateMerkleLL(
        ISablierMerkleLL indexed merkleLL,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule schedule,
        uint256 aggregateAmount,
        uint256 recipientCount,
        uint256 fee
    );

    /// @notice Emitted when a {SablierMerkleLT} campaign is created.
    event CreateMerkleLT(
        ISablierMerkleLT indexed merkleLT,
        MerkleBase.ConstructorParams baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] tranchesWithPercentages,
        uint256 totalDuration,
        uint256 aggregateAmount,
        uint256 recipientCount,
        uint256 fee
    );

    /// @notice Emitted when the admin resets the custom fee for the provided campaign creator to the default fee.
    event ResetCustomFee(address indexed admin, address indexed campaignCreator);

    /// @notice Emitted when the admin sets a custom fee for the provided campaign creator.
    event SetCustomFee(address indexed admin, address indexed campaignCreator, uint256 customFee);

    /// @notice Emitted when the default fee is set by the admin.
    event SetDefaultFee(address indexed admin, uint256 defaultFee);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the default fee charged for claiming an airdrop.
    /// @dev The fee is denominated in the native token of the chain, e.g., ETH for Ethereum Mainnet.
    function defaultFee() external view returns (uint256);

    /// @notice Retrieves the custom fee struct for the provided campaign creator.
    /// @dev The fee is denominated in the native token of the chain, e.g., ETH for Ethereum Mainnet.
    /// @param campaignCreator The address of the campaign creator.
    function getCustomFee(address campaignCreator) external view returns (MerkleFactory.CustomFee memory);

    /// @notice Retrieves the fee for the provided campaign creator, using the default fee if no custom fee is set.
    /// @dev The fee is denominated in the native token of the chain, e.g., ETH for Ethereum Mainnet.
    /// @param campaignCreator The address of the campaign creator.
    function getFee(address campaignCreator) external view returns (uint256);

    /// @notice Verifies if the sum of percentages in `tranches` equals 100%, i.e., 1e18.
    /// @dev This is a helper function for the frontend. It is not used anywhere in the contracts.
    /// @param tranches The tranches with their respective unlock percentages.
    /// @return result True if the sum of percentages equals 100%, otherwise false.
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Collects the fees accrued in the `merkleBase` contract, and transfers them to the factory admin.
    /// @dev Emits a {CollectFees} event.
    ///
    /// Notes:
    /// - If the admin is a contract, it must be able to receive native token payments, e.g., ETH for Ethereum Mainnet.
    ///
    /// @param merkleBase The address of the Merkle contract where the fees are collected from.
    function collectFees(ISablierMerkleBase merkleBase) external;

    /// @notice Creates a new MerkleInstant campaign for instant distribution of tokens.
    ///
    /// @dev Emits a {CreateMerkleInstant} event.
    ///
    /// Notes:
    /// - The MerkleInstant contract is created with CREATE2.
    /// - The immutable fee will be set to the default value unless a custom fee is set.
    ///
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleInstant The address of the newly created MerkleInstant contract.
    function createMerkleInstant(
        MerkleBase.ConstructorParams memory baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleInstant merkleInstant);

    /// @notice Creates a new Merkle Lockup campaign with a Lockup Linear distribution.
    ///
    /// @dev Emits a {CreateMerkleLL} event.
    ///
    /// Notes:
    /// - The MerkleLL contract is created with CREATE2.
    /// - The immutable fee will be set to the default value unless a custom fee is set.
    ///
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param cancelable Indicates if the stream will be cancelable after claiming.
    /// @param transferable Indicates if the stream will be transferable after claiming.
    /// @param schedule Struct encapsulating the unlocks schedule, which are documented in {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLL The address of the newly created Merkle Lockup contract.
    function createMerkleLL(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule memory schedule,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLL merkleLL);

    /// @notice Creates a new Merkle Lockup campaign with a Lockup Tranched distribution.
    ///
    /// @dev Emits a {CreateMerkleLT} event.
    ///
    /// Notes:
    /// - The MerkleLT contract is created with CREATE2.
    /// - The immutable fee will be set to the default value unless a custom fee is set.
    ///
    /// @param baseParams Struct encapsulating the {SablierMerkleBase} parameters, which are documented in
    /// {DataTypes}.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param cancelable Indicates if the stream will be cancelable after claiming.
    /// @param transferable Indicates if the stream will be transferable after claiming.
    /// @param streamStartTime The start time of the streams created through {SablierMerkleBase.claim}.
    /// @param tranchesWithPercentages The tranches with their respective unlock percentages.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLT The address of the newly created Merkle Lockup contract.
    function createMerkleLT(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLT merkleLT);

    /// @notice Resets the custom fee for the provided campaign creator to the default fee.
    /// @dev Emits a {ResetCustomFee} event.
    ///
    /// Notes:
    /// - The default fee will only be applied to future campaigns.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param campaignCreator The user for whom the fee is reset for.
    function resetCustomFee(address campaignCreator) external;

    /// @notice Sets a custom fee for the provided campaign creator.
    /// @dev Emits a {SetCustomFee} event.
    ///
    /// Notes:
    /// - The new fee will only be applied to future campaigns.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param campaignCreator The user for whom the fee is set.
    /// @param newFee The new fee to be set.
    function setCustomFee(address campaignCreator, uint256 newFee) external;

    /// @notice Sets the default fee to be applied when claiming airdrops.
    /// @dev Emits a {SetDefaultFee} event.
    ///
    /// Notes:
    /// - The new default fee will only be applied to the future campaigns and will not affect the ones already
    /// deployed.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param defaultFee The new default fee to be set.
    function setDefaultFee(uint256 defaultFee) external;
}
