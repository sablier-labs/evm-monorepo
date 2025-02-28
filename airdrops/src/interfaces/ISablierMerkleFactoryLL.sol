// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleLL } from "./../types/DataTypes.sol";
import { ISablierMerkleFactoryBase } from "./ISablierMerkleFactoryBase.sol";
import { ISablierMerkleLL } from "./ISablierMerkleLL.sol";

/// @title ISablierMerkleFactoryLL
/// @notice A contract that deploys MerkleLL campaigns.
interface ISablierMerkleFactoryLL is ISablierMerkleFactoryBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleLL} campaign is created.
    event CreateMerkleLL(
        ISablierMerkleLL indexed merkleLL,
        MerkleLL.ConstructorParams params,
        uint256 aggregateAmount,
        uint256 recipientCount,
        uint256 fee,
        address oracle
    );

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Merkle Lockup campaign with a Lockup Linear distribution.
    ///
    /// @dev Emits a {CreateMerkleLL} event.
    ///
    /// Notes:
    /// - The MerkleLL contract is created with CREATE2.
    /// - The immutable fee will be set to the minimum fee value unless a custom fee is set.
    /// - A value of zero for `params.expiration` means the campaign does not expire.
    ///
    /// @param params Struct encapsulating the input parameters, which are documented in {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLL The address of the newly created Merkle Lockup contract.
    function createMerkleLL(
        MerkleLL.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLL merkleLL);
}
