// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { IAdminable } from "./IAdminable.sol";

/// @title ISablierV2Controller
/// @notice This contract is in charge of the Sablier V2 protocol configuration, handling such values as the
/// protocol fees.
interface ISablierV2Comptroller is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin sets a new protocol fee for the provided ERC-20 asset.
    /// @param admin The address of the contract admin.
    /// @param asset The contract address of the ERC-20 asset the new protocol fee has been set for.
    /// @param oldProtocolFee The old protocol fee, denoted as a fixed-point number.
    /// @param newProtocolFee The new protocol fee, denoted as a fixed-point number.
    event SetProtocolFee(address indexed admin, IERC20 indexed asset, UD60x18 oldProtocolFee, UD60x18 newProtocolFee);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the protocol fee for all streams created with the provided ERC-20 asset.
    /// @param asset The contract address of the ERC-20 asset to query.
    /// @return fee The protocol fee denoted as a fixed-point number where 1e18 is 100%.
    function protocolFees(IERC20 asset) external view returns (UD60x18 fee);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets a new protocol fee that will be charged on all streams created with the provided ERC-20 asset.
    ///
    /// @dev Emits a {SetProtocolFee} event.
    ///
    /// Notes:
    /// - The fee is not denoted in units of the asset's decimals; it is a fixed-point number. Refer to the
    /// PRBMath documentation for more detail on the logic of UD60x18.
    /// - Does not revert if the fee is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param asset The contract address of the ERC-20 asset to update the fee for.
    /// @param newProtocolFee The new protocol fee, denoted as a fixed-point number where 1e18 is 100%.
    function setProtocolFee(IERC20 asset, UD60x18 newProtocolFee) external;
}
