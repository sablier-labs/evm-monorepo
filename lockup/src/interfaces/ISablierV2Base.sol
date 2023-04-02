// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { IAdminable } from "./IAdminable.sol";
import { ISablierV2Comptroller } from "./ISablierV2Comptroller.sol";

/// @title ISablierV2Base
/// @notice Common base between all Sablier V2 streaming contracts.
interface ISablierV2Base is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the contract admin claims all protocol revenues accrued for the provided ERC-20 asset.
    /// @param admin The address of the contract admin.
    /// @param asset The contract address of the ERC-20 asset the protocol revenues have been claimed for.
    /// @param protocolRevenues The amount of protocol revenues claimed, in units of the asset's decimals.
    event ClaimProtocolRevenues(address indexed admin, IERC20 indexed asset, uint128 protocolRevenues);

    /// @notice Emitted when the contract admin sets a new comptroller contract.
    /// @param admin The address of the contract admin.
    /// @param oldComptroller The address of the old comptroller contract.
    /// @param newComptroller The address of the new comptroller contract.
    event SetComptroller(
        address indexed admin, ISablierV2Comptroller oldComptroller, ISablierV2Comptroller newComptroller
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    /// @dev This is stored as a constant.
    function MAX_FEE() external view returns (UD60x18);

    /// @notice The address of the comptroller contract, which is in charge of the Sablier V2 protocol configuration,
    /// handling such values as the protocol fees.
    function comptroller() external view returns (ISablierV2Comptroller);

    /// @notice The protocol revenues accrued for the provided ERC-20 asset, in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to make the query for.
    function protocolRevenues(IERC20 asset) external view returns (uint128 revenues);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claims all protocol revenues accrued for the provided ERC-20 asset.
    ///
    /// @dev Emits a {ClaimProtocolRevenues} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param asset The contract address of the ERC-20 asset to claim the protocol revenues for.
    function claimProtocolRevenues(IERC20 asset) external;

    /// @notice Sets a new comptroller contract. The comptroller is in charge of the protocol configuration,
    /// handling such values as the protocol fees.
    ///
    /// @dev Emits a {SetComptroller} event.
    ///
    /// Notes:
    /// - Does not revert if the comptroller is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param newComptroller The address of the new comptroller contract.
    function setComptroller(ISablierV2Comptroller newComptroller) external;
}
