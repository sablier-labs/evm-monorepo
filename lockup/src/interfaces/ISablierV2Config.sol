// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Adminable } from "./ISablierV2Adminable.sol";
import { ISablierV2Comptroller } from "./ISablierV2Comptroller.sol";

/// @title ISablierV2Config
/// @notice This contract contains the common configuration between all Sablier V2 streaming contracts.
interface ISablierV2Config is ISablierV2Adminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the contract admin claims all protocol revenues accrued for the provided ERC-20 asset.
    /// @param admin The address of the current contract admin.
    /// @param asset The contract address of the ERC-20 asset the protocol revenues have been claimed for.
    /// @param protocolRevenues The amount of protocol revenues claimed, in units of the asset's decimals.
    event ClaimProtocolRevenues(address indexed admin, IERC20 indexed asset, uint128 protocolRevenues);

    /// @notice Emitted when the contract admin sets a new comptroller contract.
    /// @param admin The address of the current contract admin.
    /// @param oldComptroller The address of the old {SablierV2Comptroller} contract.
    /// @param newComptroller The address of the new {SablierV2Comptroller} contract.
    event SetComptroller(
        address indexed admin,
        ISablierV2Comptroller oldComptroller,
        ISablierV2Comptroller newComptroller
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    /// @dev This is initialized at construction time and cannot be changed later.
    function MAX_FEE() external view returns (UD60x18);

    /// @notice The address of the {SablierV2Comptroller} contract. The comptroller is in charge of the Sablier V2
    /// protocol configuration, handling such values as the protocol fees.
    function comptroller() external view returns (ISablierV2Comptroller);

    /// @notice Queries the protocol revenues accrued for the provided ERC-20 asset, in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to make the query for.
    function getProtocolRevenues(IERC20 asset) external view returns (uint128 protocolRevenues);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claims all protocol revenues accrued for the provided ERC-20 asset.
    ///
    /// @dev Emits a {ClaimProtocolRevenues} event.
    ///
    /// Requirements:
    /// - The caller must be the owner of the contract.
    ///
    /// @param asset The contract address of the ERC-20 asset to claim the protocol revenues for.
    function claimProtocolRevenues(IERC20 asset) external;

    /// @notice Sets the {SablierV2Comptroller} contract. The comptroller is in charge of the protocol configuration,
    /// handling such values as the protocol fees.
    ///
    /// @dev Emits a {SetComptroller} event.
    ///
    /// Notes:
    /// - Does not revert if the comptroller is the same.
    ///
    /// Requirements:
    /// - The caller must be the contract admin.
    ///
    /// @param newComptroller The address of the new {SablierV2Comptroller} contract.
    function setComptroller(ISablierV2Comptroller newComptroller) external;
}
