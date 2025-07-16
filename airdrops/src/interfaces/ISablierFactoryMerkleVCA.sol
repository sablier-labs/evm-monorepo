// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleVCA } from "./../types/DataTypes.sol";
import { ISablierFactoryMerkleBase } from "./ISablierFactoryMerkleBase.sol";
import { ISablierMerkleVCA } from "./ISablierMerkleVCA.sol";

/// @title ISablierFactoryMerkleVCA
/// @notice A factory that deploys MerkleVCA campaign contracts.
/// @dev See the documentation in {ISablierMerkleVCA}.
interface ISablierFactoryMerkleVCA is ISablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleVCA} campaign is created.
    event CreateMerkleVCA(
        ISablierMerkleVCA indexed merkleVCA,
        MerkleVCA.ConstructorParams params,
        uint256 aggregateAmount,
        uint256 recipientCount,
        address comptroller,
        uint256 minFeeUSD
    );

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Computes the deterministic address where {SablierMerkleVCA} campaign will be deployed.
    /// @dev Reverts if the requirements from {createMerkleVCA} are not met.
    function computeMerkleVCA(
        address campaignCreator,
        MerkleVCA.ConstructorParams memory params
    )
        external
        view
        returns (address merkleVCA);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new MerkleVCA campaign for variable distribution of tokens.
    ///
    /// @dev Emits a {CreateMerkleVCA} event.
    ///
    /// Notes:
    /// - The contract is created with CREATE2.
    /// - The campaign's fee will be set to the min USD fee unless a custom fee is set for `msg.sender`.
    /// - Users interested into funding the campaign before its deployment must meet the below requirements, otherwise
    /// the campaign deployment will revert.
    ///
    /// Requirements:
    /// - `params.token` must not be the forbidden native token.
    /// - `params.expiration` must be greater than 0.
    /// - `params.expiration` must be at least 1 week beyond the end time to ensure loyal recipients have enough time to
    /// claim.
    /// - `params.vestingEndTime` must be greater than `params.vestingStartTime`.
    /// - Both `params.vestingStartTime` and `params.vestingEndTime` must be greater than 0.
    /// - `params.unlockPercentage` must not be greater than 1e18, equivalent to 100%.
    ///
    /// @param params Struct encapsulating the {SablierMerkleVCA} parameters, which are documented in {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipient addresses eligible for the airdrop.
    /// @return merkleVCA The address of the newly created MerkleVCA campaign.
    function createMerkleVCA(
        MerkleVCA.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleVCA merkleVCA);
}
