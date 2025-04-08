// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAdminable } from "@sablier/evm-utils/src/interfaces/IAdminable.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";

/// @title ISablierFactoryMerkleBase
/// @dev Common interface between factories that deploy campaign contracts. The contracts are deployed using CREATE2.
interface ISablierFactoryMerkleBase is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the accrued fees are collected.
    event CollectFees(
        address indexed admin, ISablierMerkleBase indexed campaign, address indexed feeRecipient, uint256 feeAmount
    );

    /// @notice Emitted when the admin resets the custom USD fee for the provided campaign creator to the min fee.
    event DisableCustomFeeUSD(address indexed admin, address indexed campaignCreator);

    /// @notice Emitted when the admin sets a custom USD fee for the provided campaign creator.
    event SetCustomFeeUSD(address indexed admin, address indexed campaignCreator, uint256 customFeeUSD);

    /// @notice Emitted when the min USD fee is set by the admin.
    event SetMinFeeUSD(address indexed admin, uint256 newMinFeeUSD, uint256 previousMinFeeUSD);

    /// @notice Emitted when the native token address is set by the admin.
    event SetNativeToken(address indexed admin, address nativeToken);

    /// @notice Emitted when the oracle contract address is set by the admin.
    event SetOracle(address indexed admin, address newOracle, address previousOracle);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the maximum USD fee that can be set for claim fee.
    /// @dev The returned value is 100e8, which is equivalent to $100.
    function MAX_FEE_USD() external view returns (uint256);

    /// @notice Determines the min USD fee applicable for the provided campaign creator. By default, the min USD fee is
    /// applied unless there is a custom USD fee set.
    /// @param campaignCreator The address of the campaign creator.
    /// @return The min USD fee, denominated in Chainlink's 8-decimal format for USD prices.
    function minFeeUSDFor(address campaignCreator) external view returns (uint256);

    /// @notice Retrieves the min USD fee required to claim the airdrop, paid in the native token of the chain, e.g.,
    /// ETH for Ethereum Mainnet.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function minFeeUSD() external view returns (uint256);

    /// @notice Retrieves the address of the ERC-20 interface of the native token, if it exists.
    /// @dev The native tokens on some chains have a dual interface as ERC-20. For example, on Polygon the $POL token
    /// is the native token and has an ERC-20 version at 0x0000000000000000000000000000000000001010. This means
    /// that `address(this).balance` returns the same value as `balanceOf(address(this))`. To avoid any unintended
    /// behavior, these tokens cannot be used in Sablier. As an alternative, users can use the Wrapped version of the
    /// token, i.e. WMATIC, which is a standard ERC-20 token.
    function nativeToken() external view returns (address);

    /// @notice Retrieves the oracle contract address, which provides price data for the native token.
    function oracle() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Collects the fees accrued in the given campaign contract. If `feeRecipient` is a contract, it must be
    /// able to receive native tokens, e.g., ETH for Ethereum Mainnet.
    /// @dev Emits a {CollectFees} event.
    ///
    /// Requirements:
    /// - If `msg.sender` is not the admin, `feeRecipient` must be the admin address.
    ///
    /// @param campaign The address of the Merkle contract to collect the fees from.
    /// @param feeRecipient The address where the fees will be collected.
    function collectFees(ISablierMerkleBase campaign, address feeRecipient) external;

    /// @notice Disables the custom USD fee for the provided campaign creator, who will now pay the min USD fee.
    /// @dev Emits a {DisableCustomFee} event.
    ///
    /// Notes:
    /// - The min fee will apply only to future campaigns. Fees for past campaigns remain unchanged.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param campaignCreator The user to disable the custom fee for.
    function disableCustomFeeUSD(address campaignCreator) external;

    /// @notice Sets a custom USD fee for the provided campaign creator.
    /// @dev Emits a {SetCustomFee} event.
    ///
    /// Notes:
    /// - The custom USD fee will apply only to future campaigns. Fees for past campaigns remain unchanged.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param campaignCreator The user for whom the fee is set.
    /// @param customFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setCustomFeeUSD(address campaignCreator, uint256 customFeeUSD) external;

    /// @notice Sets the min USD fee for upcoming campaigns.
    /// @dev Emits a {SetMinFeeUSD} event.
    ///
    /// Notes:
    /// - The new USD fee will apply only to future campaigns. Fees for past campaigns remain unchanged.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param newMinFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setMinFeeUSD(uint256 newMinFeeUSD) external;

    /// @notice Sets the native token address. Once set, it cannot be changed.
    /// @dev For more information, see the documentation for {nativeToken}.
    ///
    /// Emits a {SetNativeToken} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - `newNativeToken` must not be zero address.
    /// - The native token must not be already set.
    /// @param newNativeToken The address of the native token.
    function setNativeToken(address newNativeToken) external;

    /// @notice Sets the oracle contract address. The zero address can be used to disable the oracle.
    /// @dev Emits a {SetOracle} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - If `newOracle` is not the zero address, the call to it must not fail.
    ///
    /// @param newOracle The new oracle contract address. It can be the zero address.
    function setOracle(address newOracle) external;
}
