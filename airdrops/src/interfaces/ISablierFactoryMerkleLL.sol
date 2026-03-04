// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleLL } from "../types/MerkleLL.sol";
import { ISablierFactoryMerkleBase } from "./ISablierFactoryMerkleBase.sol";
import { ISablierMerkleLL } from "./ISablierMerkleLL.sol";

/// @title ISablierFactoryMerkleLL
/// @notice A factory that deploys MerkleLL campaign contracts.
/// @dev See the documentation in {ISablierMerkleLL}.
interface ISablierFactoryMerkleLL is ISablierFactoryMerkleBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleLL} campaign is created.
    event CreateMerkleLL(
        ISablierMerkleLL indexed merkleLL,
        MerkleLL.ConstructorParams campaignParams,
        uint256 aggregateAmount,
        uint256 recipientCount,
        address comptroller,
        uint256 minFeeUSD
    );

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Computes the deterministic address where {SablierMerkleLL} campaign will be deployed.
    /// @dev Reverts if the requirements from {createMerkleLL} are not met.
    function computeMerkleLL(
        address campaignCreator,
        MerkleLL.ConstructorParams calldata campaignParams
    )
        external
        view
        returns (address merkleLL);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Merkle Lockup campaign with a Lockup Linear distribution.
    ///
    /// @dev Emits a {CreateMerkleLL} event.
    ///
    /// Notes:
    /// - The contract is created with CREATE2.
    /// - The campaign's fee will be set to the min USD fee unless a custom fee is set for `msg.sender`.
    /// - A value of zero for `campaignParams.expiration` means the campaign does not expire.
    /// - A value of zero for `campaignParams.granularity` would store the granularity as 1 second.
    ///
    /// Requirements:
    /// - `campaignParams.token` must not be the forbidden native token.
    ///
    /// @param campaignParams Struct encapsulating the {SablierMerkleLL} parameters.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipient addresses eligible for the airdrop.
    /// @return merkleLL The address of the newly created Merkle Lockup contract.
    function createMerkleLL(
        MerkleLL.ConstructorParams memory campaignParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLL merkleLL);
}
