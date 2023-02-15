// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Adminable } from "./ISablierV2Adminable.sol";

/// @title ISablierV2Controller
/// @notice This contract is in charge of the Sablier V2 protocol configuration, handling such values as the
/// protocol fees.
interface ISablierV2Comptroller is ISablierV2Adminable {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The global flash fee as an UD60x18 number where 100% = 1e18.
    /// @dev Notes:
    /// - This is a fee percentage, not a fee amount. This should not be confused with the
    /// {IERC3156FlashLender-flashFee} function, which returns the fee amount for a given flash loan amount.
    /// - Unlike the protocol fee, this is not a per-asset fee. It's a global fee applied to all flash loans.
    function flashFee() external view returns (UD60x18);

    /// @notice Queries the protocol fee charged on all streams created with the provided ERC-20 asset across
    /// all Sablier V2 contracts.
    /// @param asset The contract address of the ERC-20 asset to make the query for.
    /// @return protocolFee The protocol fee as an UD60x18 number where 100% = 1e18.
    function getProtocolFee(IERC20 asset) external view returns (UD60x18 protocolFee);

    /// @notice Checks whether the provided ERC-20 asset is flash loanable or not.
    /// @param token The contract address of the ERC-20 asset to make the query for.
    function isFlashLoanable(IERC20 token) external view returns (bool result);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets a new flash fee that will be charged on all flash loans made with any ERC-20 asset.
    ///
    /// @dev Emits a {SetFlashFee} event.
    ///
    /// Notes:
    /// - Does not revert if the fee is the same.
    ///
    /// Requirements:
    /// - The caller must be the contract admin.
    ///
    /// @param newFlashFee The new flash fee to set, as an UD60x18 number where 100% = 1e18.
    function setFlashFee(UD60x18 newFlashFee) external;

    /// @notice Sets a new protocol fee that will be charged on all streams created with the provided ERC-20 asset
    /// across all Sablier V2 contracts.
    ///
    /// @dev Emits a {SetProtocolFee} event.
    ///
    /// Notes:
    /// - The fee is not in units of the asset's decimals, but in the UD60x18 number format. Refer to the PRBMath
    /// documentation for more detail on the logic of UD60x18.
    /// - Does not revert if the fee is the same.
    ///
    /// Requirements:
    /// - The caller must be the contract admin.
    ///
    /// @param asset The contract address of the ERC-20 asset to make the query for.
    /// @param newProtocolFee The new protocol fee to set, as an UD60x18 number where 100% = 1e18.
    function setProtocolFee(IERC20 asset, UD60x18 newProtocolFee) external;

    /// @notice Toggles the flash loanability of an ERC-20 asset. This flag is applied to all Sablier V2 contracts.
    ///
    /// @dev Emits a {ToggleFlashAsset} event.
    ///
    /// Requirements:
    /// - The caller must be the admin.
    ///
    /// @param asset The address of the ERC-20 asset to toggle.
    function toggleFlashAsset(IERC20 asset) external;
}
