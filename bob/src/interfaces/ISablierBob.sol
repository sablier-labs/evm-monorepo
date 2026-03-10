// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IComptrollerable } from "@sablier/evm-utils/src/interfaces/IComptrollerable.sol";

import { IBobVaultShare } from "./IBobVaultShare.sol";
import { ISablierBobAdapter } from "./ISablierBobAdapter.sol";
import { ISablierBobState } from "./ISablierBobState.sol";

/// @title ISablierBob
/// @notice Price-gated vaults that unlock deposited tokens when the price returned by the oracle is greater than or
/// equal to the target price set by the vault creator. The tokens are also unlocked if the vault expires. When a vault
/// is configured with a adapter, the protocol automatically stakes the tokens via adapter and earns yield on the
/// deposit amount.
interface ISablierBob is IComptrollerable, ISablierBobState {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new vault is created.
    event CreateVault(
        uint256 indexed vaultId,
        IERC20 indexed token,
        AggregatorV3Interface indexed oracle,
        ISablierBobAdapter adapter,
        IBobVaultShare shareToken,
        uint128 targetPrice,
        uint40 expiry
    );

    /// @notice Emitted when a user deposits tokens into a vault.
    event Enter(uint256 indexed vaultId, address indexed user, uint128 amountReceived, uint128 sharesMinted);

    /// @notice Emitted when a user redeems their shares from a settled vault.
    event Redeem(
        uint256 indexed vaultId,
        address indexed user,
        uint128 amountReceived,
        uint128 sharesBurned,
        uint256 fee
    );

    /// @notice Emitted when the comptroller sets a new default adapter for a token.
    event SetDefaultAdapter(IERC20 indexed token, ISablierBobAdapter indexed adapter);

    /// @notice Emitted when the native token address is set by the comptroller.
    event SetNativeToken(address indexed comptroller, address nativeToken);

    /// @notice Emitted when a vault's price is synced from the oracle.
    event SyncPriceFromOracle(
        uint256 indexed vaultId,
        AggregatorV3Interface indexed oracle,
        uint128 latestPrice,
        uint40 syncedAt
    );

    /// @notice Emitted when tokens staked in the adapter for a given vault are unstaked.
    event UnstakeFromAdapter(
        uint256 indexed vaultId,
        ISablierBobAdapter indexed adapter,
        uint128 wrappedTokenUnstakedAmount,
        uint128 amountReceivedFromAdapter
    );

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the minimum fee in wei required to redeem from the given vault ID. Returns 0 for vaults with
    /// an adapter, since the fee is taken from yield generated.
    /// @dev Reverts if `vaultId` references a null vault.
    /// @param vaultId The vault ID for the query.
    function calculateMinFeeWei(uint256 vaultId) external view returns (uint256 minFeeWei);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new vault with the specified parameters.
    ///
    /// @dev Emits a {CreateVault} event.
    ///
    /// Notes:
    /// - A new ERC-20 share token is deployed for each vault to represent user's share of deposits in the vault.
    /// - The default adapter for the token is copied as the vault adapter. Any change in the default adapter does not
    /// affect existing vaults.
    /// - Vault creator is responsible for choosing a valid oracle. They should use Chainlink oracles, as the
    /// integration is based on their API.
    ///
    /// Requirements:
    /// - `token` must not be the zero address.
    /// - `token` must implement `symbol()` and `decimals()` functions.
    /// - `expiry` must be in the future.
    /// - `oracle` must implement the Chainlink's {AggregatorV3Interface} interface.
    /// - `oracle` must return a positive price when `latestRoundData()` is called.
    /// - `oracle` must return a non-zero value no greater than 36 when `decimals()` is called.
    /// - `targetPrice` must not be zero or greater than the current price returned by the provided oracle.
    ///
    /// @param token The address of the ERC-20 token that will be accepted for deposits.
    /// @param oracle The address of the price feed oracle for the deposit token.
    /// @param expiry The Unix timestamp when the vault expires.
    /// @param targetPrice The target price at which the vault settles, denominated in Chainlink's 8-decimal format for
    /// USD prices, where 1e8 is $1.
    /// @return vaultId The ID of the newly created vault.
    function createVault(
        IERC20 token,
        AggregatorV3Interface oracle,
        uint40 expiry,
        uint128 targetPrice
    )
        external
        returns (uint256 vaultId);

    /// @notice Enter into a vault by depositing tokens into it and minting share tokens to the caller.
    ///
    /// @dev Emits an {Enter} event.
    ///
    /// Notes:
    /// - If an adapter is configured for the vault, tokens are automatically staked for yield using the adapter.
    /// - Share tokens are minted 1:1 with the deposited amount.
    ///
    /// Requirements:
    /// - The vault must have ACTIVE status.
    /// - `amount` must be greater than zero.
    /// - The caller must have approved this contract to transfer `amount` tokens.
    ///
    /// @param vaultId The ID of the vault to deposit into.
    /// @param amount The amount of tokens to deposit.
    function enter(uint256 vaultId, uint128 amount) external;

    /// @notice Enter into a vault by depositing ETH which is wrapped into WETH.
    ///
    /// @dev Emits an {Enter} event.
    ///
    /// Notes:
    /// - `msg.value` is used as the deposit amount and is safe-cast to `uint128`.
    /// - If an adapter is configured for the vault, tokens are automatically staked for yield using the adapter.
    /// - Share tokens are minted 1:1 with the deposited amount.
    ///
    /// Requirements:
    /// - `vaultId` must not reference a null vault.
    /// - The vault must have ACTIVE status.
    /// - `msg.value` must be greater than zero and fit in `uint128`.
    ///
    /// @param vaultId The ID of the vault to deposit into.
    function enterWithNativeToken(uint256 vaultId) external payable;

    /// @notice Called by adapter when share tokens for a given vault are transferred between users. This is required
    /// for accounting of the yield generated by the adapter.
    ///
    /// Requirements:
    /// - The caller must be the share token contract stored in the given vault.
    /// - The calculated wstETH transfer amount must not be zero.
    ///
    /// @param vaultId The ID of the vault.
    /// @param from The address transferring share tokens.
    /// @param to The address receiving share tokens.
    /// @param amount The number of share tokens being transferred.
    /// @param fromBalanceBefore The number of share tokens the sender had before the transfer.
    function onShareTransfer(
        uint256 vaultId,
        address from,
        address to,
        uint256 amount,
        uint256 fromBalanceBefore
    )
        external;

    /// @notice Redeem the tokens by burning user shares.
    ///
    /// @dev Emits a {Redeem} event.
    ///
    /// Notes:
    /// - If no adapter is configured for the vault, a fee in the native token is applied.
    /// - If an adapter is configured for the vault, a fee, in the deposit token, is deducted from yield generated by
    /// the adapter.
    /// - If unstake via Lido withdrawal queue contract is triggered, redeem will revert until the withdrawal from the
    /// Lido queue is finalized.
    ///
    /// Requirements:
    /// - Either block timestamp must be greater than or equal to the vault expiry or the latest price from the oracle
    /// must be greater than or equal to the target price.
    /// - The share balance of the caller must be greater than zero.
    /// - If no adapter is configured for the vault, `msg.value` must be greater than or equal to the min fee required
    /// in the native token.
    ///
    /// @param vaultId The ID of the vault to redeem from.
    /// @return transferAmount The amount of tokens transferred to the caller, after fees are deducted (only applicable
    /// if adapter is set).
    /// @return feeAmountDeductedFromYield The fee amount deducted from the yield. Zero if no adapter is set.
    function redeem(uint256 vaultId)
        external
        payable
        returns (uint128 transferAmount, uint128 feeAmountDeductedFromYield);

    /// @notice Sets the default adapter for a specific token.
    ///
    /// @dev Emits a {SetDefaultAdapter} event.
    ///
    /// Notes:
    /// - This only affects future vaults.
    ///
    /// Requirements:
    /// - The caller must be the comptroller.
    /// - If new adapter is not zero address, it must implement {ISablierBobAdapter} interface.
    ///
    /// @param token The token address to set the adapter for.
    /// @param newAdapter The address of the new adapter.
    function setDefaultAdapter(IERC20 token, ISablierBobAdapter newAdapter) external;

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

    /// @notice Fetches the latest price from the oracle set for a vault and updates it in the vault storage.
    ///
    /// @dev Emits a {SyncPriceFromOracle} event.
    ///
    /// Notes:
    /// - Oracle staleness is not validated on-chain when calling this function. Any price returned by the oracle is
    /// accepted.
    /// - Useful for syncing the price from oracle without calling {redeem} or {enter}. This function can be called by
    /// anyone to settle vault when the price is above the target price.
    ///
    /// Requirements:
    /// - The vault must have ACTIVE status.
    /// - The oracle must return a positive price.
    ///
    /// @param vaultId The ID of the vault to sync.
    /// @return latestPrice The latest price fetched from the oracle, denominated in Chainlink's 8-decimal format for
    /// USD prices, where 1e8 is $1.
    function syncPriceFromOracle(uint256 vaultId) external returns (uint128 latestPrice);

    /// @notice Unstake all tokens from the adapter for a given vault.
    ///
    /// @dev Emits an {UnstakeFromAdapter} event.
    ///
    /// Requirements:
    /// - The adapter set in the vault must not be zero address.
    /// - Either block timestamp must be greater than or equal to the vault expiry or the latest price from the oracle
    /// must be greater than or equal to the target price.
    /// - The vault must not have been unstaked already.
    /// - The amount staked must be greater than zero.
    ///
    /// @param vaultId The ID of the vault.
    /// @return amountReceivedFromAdapter The amount of tokens received from the adapter.
    function unstakeTokensViaAdapter(uint256 vaultId) external returns (uint128 amountReceivedFromAdapter);
}
