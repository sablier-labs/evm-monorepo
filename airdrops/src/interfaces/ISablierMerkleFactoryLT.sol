// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { MerkleLT } from "./../types/DataTypes.sol";
import { ISablierMerkleFactoryBase } from "./ISablierMerkleFactoryBase.sol";
import { ISablierMerkleLT } from "./ISablierMerkleLT.sol";

/// @title ISablierMerkleFactoryLT
/// @notice A contract that deploys MerkleLT campaigns.
interface ISablierMerkleFactoryLT is ISablierMerkleFactoryBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a {SablierMerkleLT} campaign is created.
    event CreateMerkleLT(
        ISablierMerkleLT indexed merkleLT,
        MerkleLT.ConstructorParams params,
        uint256 aggregateAmount,
        uint256 recipientCount,
        uint256 totalDuration,
        uint256 fee
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

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

    /// @notice Creates a new Merkle Lockup campaign with a Lockup Tranched distribution.
    ///
    /// @dev Emits a {CreateMerkleLT} event.
    ///
    /// Notes:
    /// - The MerkleLT contract is created with CREATE2.
    /// - The immutable fee will be set to the minimum value unless a custom fee is set.
    /// - A value of zero for `params.expiration` means the campaign does not expire.
    ///
    /// @param params Struct encapsulating the input parameters, which are documented in {DataTypes}.
    /// @param aggregateAmount The total amount of ERC-20 tokens to be distributed to all recipients.
    /// @param recipientCount The total number of recipients who are eligible to claim.
    /// @return merkleLT The address of the newly created Merkle Lockup contract.
    function createMerkleLT(
        MerkleLT.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleLT merkleLT);
}
