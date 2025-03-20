// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAdminable } from "@sablier/evm-utils/src/interfaces/IAdminable.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";

/// @title ISablierMerkleFactoryBase
/// @dev Common interface between Merkle factories. All contracts deployed use Merkle proofs for token distribution.
/// Merkle Lockup enables Airstreams, a portmanteau of "airdrop" and "stream," an airdrop model where the tokens are
/// distributed over time, as opposed to all at once. Merkle Instant enables instant airdrops where tokens are unlocked
/// and distributed immediately. Merkle VCA enables a new flavor of airdrop model where the claim amount depends on how
/// late a user claims their airdrop. See the Sablier docs for more guidance: https://docs.sablier.com
/// @dev The contracts are deployed using CREATE2.
interface ISablierMerkleFactoryBase is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the accrued fees are collected.
    event CollectFees(address indexed admin, ISablierMerkleBase indexed merkleBase, uint256 feeAmount);

    /// @notice Emitted when the admin resets the custom fee for the provided campaign creator to the minimum fee.
    event ResetCustomFee(address indexed admin, address indexed campaignCreator);

    /// @notice Emitted when the admin sets a custom fee for the provided campaign creator.
    event SetCustomFee(address indexed admin, address indexed campaignCreator, uint256 customFee);

    /// @notice Emitted when the minimum fee is set by the admin.
    event SetMinimumFee(address indexed admin, uint256 minimumFee);

    /// @notice Emitted when the native token address is set by the admin.
    event SetNativeToken(address indexed admin, address nativeToken);

    /// @notice Emitted when the oracle contract address is set by the admin.
    event SetOracle(address indexed admin, address newOracle, address previousOracle);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the maximum value that can be set for claim fee.
    /// @dev The returned value is 100e8, which is equivalent to $100.
    function MAX_FEE() external view returns (uint256);

    /// @notice Retrieves the fee for the provided campaign creator, using the minimum fee if no custom fee is set.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    /// @param campaignCreator The address of the campaign creator.
    function getFee(address campaignCreator) external view returns (uint256);

    /// @notice Retrieves the minimum fee required to claim the airdrop, paid in the native token of the
    /// chain, e.g., ETH for Ethereum Mainnet.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function minimumFee() external view returns (uint256);

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

    /// @notice Collects the fees accrued in the `merkleBase` contract, and transfers them to the factory admin.
    /// @dev Emits a {CollectFees} event.
    ///
    /// Notes:
    /// - If the admin is a contract, it must be able to receive native token payments, e.g., ETH for Ethereum Mainnet.
    ///
    /// @param merkleBase The address of the Merkle contract where the fees are collected from.
    function collectFees(ISablierMerkleBase merkleBase) external;

    /// @notice Resets the custom fee for the provided campaign creator to the minimum fee.
    /// @dev Emits a {ResetCustomFee} event.
    ///
    /// Notes:
    /// - The minimum fee will only be applied to future campaigns.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param campaignCreator The user for whom the fee is reset for.
    function resetCustomFee(address campaignCreator) external;

    /// @notice Sets a custom fee for the provided campaign creator.
    /// @dev Emits a {SetCustomFee} event.
    ///
    /// Notes:
    /// - The new fee will only be applied to future campaigns.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param campaignCreator The user for whom the fee is set.
    /// @param newFee The new fee to set.
    function setCustomFee(address campaignCreator, uint256 newFee) external;

    /// @notice Sets the minimum fee to be applied when claiming airdrops.
    /// @dev Emits a {SetMinimumFee} event.
    ///
    /// Notes:
    /// - The new minimum fee will only be applied to the future campaigns and will not affect the ones already
    /// deployed.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param newFee The new minimum fee to set.
    function setMinimumFee(uint256 newFee) external;

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

    /// @notice Sets the oracle contract address.
    /// @dev Emits a {SetOracle} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - If `newOracle` is not the zero address, the call to it must not fail.
    ///
    /// @param newOracle The new oracle contract address.
    function setOracle(address newOracle) external;
}
