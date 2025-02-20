// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleInstant } from "./../types/DataTypes.sol";
import { ISablierMerkleFactoryBase } from "./ISablierMerkleFactoryBase.sol";
import { ISablierMerkleInstant } from "./ISablierMerkleInstant.sol";

/// @title ISablierMerkleFactoryInstant
/// @notice A contract that deploys MerkleInstant campaigns.
interface ISablierMerkleFactoryInstant is ISablierMerkleFactoryBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleInstant} campaign is created.
    event CreateMerkleInstant(
        ISablierMerkleInstant indexed merkleInstant,
        MerkleInstant.ConstructorParams params,
        uint256 aggregateAmount,
        uint256 recipientCount,
        uint256 fee
    );

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new MerkleInstant campaign for instant distribution of tokens.
    ///
    /// @dev Emits a {CreateMerkleInstant} event.
    ///
    /// Notes:
    /// - The MerkleInstant contract is created with CREATE2.
    /// - The immutable fee will be set to the minimum fee value unless a custom fee is set.
    /// - A value of zero for `params.expiration` means the campaign does not expire.
    ///
    /// @param params Struct encapsulating the input parameters, which are documented in {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleInstant The address of the newly created MerkleInstant contract.
    function createMerkleInstant(
        MerkleInstant.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleInstant merkleInstant);
}
