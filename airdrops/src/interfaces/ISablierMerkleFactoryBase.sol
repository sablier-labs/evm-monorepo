// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAdminable } from "@sablier/evm-utils/src/interfaces/IAdminable.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";
import { MerkleFactory } from "../types/DataTypes.sol";

/// @title ISablierMerkleFactoryBase
/// @dev Common interface between Merkle factories. All contracts deployed use Merkle proofs for token distribution.
/// Merkle Lockup enables Airstreams, a portmanteau of "airdrop" and "stream," an airdrop model where the tokens are
/// distributed over time, as opposed to all at once. Merkle Instant enables instant airdrops where tokens are unlocked
/// and distributed immediately. Merkle VCA enables a new flavor of airdrop model where the claim amount depends on how
/// late a user claims their airdrop. See the Sablier docs for more guidance: https://docs.sablier.com
/// @dev The contracts are deployed using CREATE2.
interface ISablierMerkleFactoryBase is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the accrued fees are collected.
    event CollectFees(address indexed admin, ISablierMerkleBase indexed merkleBase, uint256 feeAmount);

    /// @notice Emitted when the admin resets the custom fee for the provided campaign creator to the minimum fee.
    event ResetCustomFee(address indexed admin, address indexed campaignCreator);

    /// @notice Emitted when the admin sets a custom fee for the provided campaign creator.
    event SetCustomFee(address indexed admin, address indexed campaignCreator, uint256 customFee);

    /// @notice Emitted when the minimum fee is set by the admin.
    event SetMinimumFee(address indexed admin, uint256 minimumFee);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the custom fee struct for the provided campaign creator.
    /// @dev The fee is denominated in the native token of the chain, e.g., ETH for Ethereum Mainnet.
    /// @param campaignCreator The address of the campaign creator.
    function getCustomFee(address campaignCreator) external view returns (MerkleFactory.CustomFee memory);

    /// @notice Retrieves the fee for the provided campaign creator, using the minimum fee if no custom fee is set.
    /// @dev The fee is denominated in the native token of the chain, e.g., ETH for Ethereum Mainnet.
    /// @param campaignCreator The address of the campaign creator.
    function getFee(address campaignCreator) external view returns (uint256);

    /// @notice Retrieves the minimum fee charged for claiming an airdrop.
    /// @dev The fee is denominated in the native token of the chain, e.g., ETH for Ethereum Mainnet.
    function minimumFee() external view returns (uint256);

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

    /// @notice Resets the custom fee for the provided campaign creator to the minimum fee.
    /// @dev Emits a {ResetCustomFee} event.
    ///
    /// Notes:
    /// - The minimum fee will only be applied to future campaigns.
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

    /// @notice Sets the minimum fee to be applied when claiming airdrops.
    /// @dev Emits a {SetMinimumFee} event.
    ///
    /// Notes:
    /// - The new minimum fee will only be applied to the future campaigns and will not affect the ones already
    /// deployed.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param minimumFee The new minimum fee to be set.
    function setMinimumFee(uint256 minimumFee) external;
}
