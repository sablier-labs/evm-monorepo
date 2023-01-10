// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { IAdminable } from "@prb/contracts/access/IAdminable.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @title ISablierV2Controller
/// @notice This contract is in charge of the Sablier V2 protocol configuration, handling such values as the
/// protocol fees.
interface ISablierV2Comptroller is IAdminable {
    /// @notice Queries the protocol fee charged on all Sablier V2 streams created with the provided token, as an
    /// UD60x18 number where 100% = 1e18.
    /// @param token The address of the token to make the query for.
    function getProtocolFee(IERC20 token) external view returns (UD60x18 protocolFee);

    /// @notice Sets a new protocol fee that will be charged on all streams created with the provided token.
    ///
    /// @dev Emits a {SetProtocolFee} event.
    ///
    /// Notes:
    /// - The fee is not in units of the token's decimals, instead it follows the UD60x18 number format. Refer to the
    /// PRBMath documentation for more detail on the logic of UD60x18.
    /// - Does not revert if the fee is the same.
    ///
    /// Requirements:
    /// - The caller must be the admin of the contract.
    /// - The new protocol fee cannot be greater than `MAX_FEE`.
    ///
    /// @param token The address of the token to make the query for.
    /// @param newProtocolFee The new protocol fee to set, as an UD60x18 number where 100% = 1e18.
    function setProtocolFee(IERC20 token, UD60x18 newProtocolFee) external;
}
