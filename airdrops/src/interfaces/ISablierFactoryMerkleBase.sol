// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IComptrollerManager } from "@sablier/evm-utils/src/interfaces/IComptrollerManager.sol";

/// @title ISablierFactoryMerkleBase
/// @dev Common interface between factories that deploy campaign contracts. The contracts are deployed using CREATE2.
interface ISablierFactoryMerkleBase is IComptrollerManager {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the native token address is set by the comptroller.
    event SetNativeToken(address indexed comptroller, address nativeToken);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the address of the ERC-20 interface of the native token, if it exists.
    /// @dev The native tokens on some chains have a dual interface as ERC-20. For example, on Polygon the $POL token
    /// is the native token and has an ERC-20 version at 0x0000000000000000000000000000000000001010. This means
    /// that `address(this).balance` returns the same value as `balanceOf(address(this))`. To avoid any unintended
    /// behavior, these tokens cannot be used in Sablier. As an alternative, users can use the Wrapped version of the
    /// token, i.e. WMATIC, which is a standard ERC-20 token.
    function nativeToken() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the native token address. Once set, it cannot be changed.
    /// @dev For more information, see the documentation for {nativeToken}.
    ///
    /// Emits a {SetNativeToken} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller.
    /// - `newNativeToken` must not be zero address.
    /// - The native token must not be already set.
    /// @param newNativeToken The address of the native token.
    function setNativeToken(address newNativeToken) external;
}
