// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleVCA } from "./../types/DataTypes.sol";
import { ISablierMerkleFactoryBase } from "./ISablierMerkleFactoryBase.sol";
import { ISablierMerkleVCA } from "./ISablierMerkleVCA.sol";

/// @title ISablierMerkleFactoryVCA
/// @notice A contract that deploys MerkleVCA campaigns.
interface ISablierMerkleFactoryVCA is ISablierMerkleFactoryBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleVCA} campaign is created.
    event CreateMerkleVCA(
        ISablierMerkleVCA indexed merkleVCA,
        MerkleVCA.ConstructorParams params,
        uint256 aggregateAmount,
        uint256 recipientCount,
        uint256 fee,
        address oracle
    );

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new MerkleVCA campaign for variable distribution of tokens.
    ///
    /// @dev Emits a {CreateMerkleVCA} event.
    ///
    /// Notes:
    /// - The MerkleVCA contract is created with CREATE2.
    /// - The immutable fee will be set to the minimum fee value unless a custom fee is set.
    /// - Users interested into funding the campaign before its deployment must meet the below requirements, otherwise
    /// the campaign deployment will revert.
    ///
    /// Requirements:
    /// - The value of `params.expiration` must not be zero.
    /// - The value of `params.expiration` must be at least 1 week beyond the unlock end time to ensure loyal recipients
    /// have enough time to claim.
    /// - `params.timestamps.end` must be greater than `params.timestamps.start`.
    /// - Both `params.timestamps.start` and `params.timestamps.end` must be non-zero.
    ///
    /// @param params Struct encapsulating the {SablierMerkleVCA} parameters, which are documented in {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleVCA The address of the newly created MerkleVCA campaign.
    function createMerkleVCA(
        MerkleVCA.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleVCA merkleVCA);
}
