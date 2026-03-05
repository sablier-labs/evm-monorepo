// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { IComptrollerable } from "@sablier/evm-utils/src/interfaces/IComptrollerable.sol";

/// @title ISablierBobAdapter
/// @notice Base interface for adapters used by the SablierBob protocol for generating yield.
interface ISablierBobAdapter is IComptrollerable, IERC165 {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the comptroller sets a new yield fee.
    event SetYieldFee(UD60x18 previousFee, UD60x18 newFee);

    /// @notice Emitted when tokens are staked for a user in a vault.
    event Stake(uint256 indexed vaultId, address indexed user, uint256 depositAmount, uint256 wrappedStakedAmount);

    /// @notice Emitted when staked token attribution is transferred between users.
    event TransferStakedTokens(uint256 indexed vaultId, address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when all staked tokens in a vault are converted back to the deposit token.
    event UnstakeFullAmount(uint256 indexed vaultId, uint128 totalStakedAmount, uint128 amountReceivedFromUnstaking);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum yield fee, denominated in UD60x18, where 1e18 = 100%.
    /// @dev This is a constant state variable.
    function MAX_FEE() external view returns (UD60x18);

    /// @notice Returns the address of the SablierBob contract.
    /// @dev This is an immutable state variable.
    function SABLIER_BOB() external view returns (address);

    /// @notice Returns the current global fee on yield for new vaults, denominated in UD60x18, where 1e18 = 100%.
    function feeOnYield() external view returns (UD60x18);

    /// @notice Returns the total amount of yield-bearing tokens held in a vault.
    /// @param vaultId The ID of the vault.
    /// @return The total amount of yield-bearing tokens in the vault.
    function getTotalYieldBearingTokenBalance(uint256 vaultId) external view returns (uint128);

    /// @notice Returns the yield fee stored for a specific vault.
    /// @param vaultId The ID of the vault.
    /// @return The yield fee for the vault denominated in UD60x18, where 1e18 = 100%.
    function getVaultYieldFee(uint256 vaultId) external view returns (UD60x18);

    /// @notice Returns the amount of yield-bearing tokens held for a specific user in a vault.
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user.
    /// @return The amount of yield-bearing tokens the user has claim to.
    function getYieldBearingTokenBalanceFor(uint256 vaultId, address user) external view returns (uint128);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Processes a user's token redemption by calculating the transfer amount, clearing the user's
    /// yield-bearing token balance, and returning the amounts.
    ///
    /// Notes:
    /// - The user's yield-bearing token balance is decremented after calculating the transfer amount. This does not
    /// decrement the vault total as it is used in the calculation of the transfer amount for other users.
    ///
    /// Requirements:
    /// - The caller must be the SablierBob contract.
    ///
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user.
    /// @param shareBalance The user's share balance in the vault.
    /// @return transferAmount The amount to transfer to the user.
    /// @return feeAmountDeductedFromYield The fee amount taken from the yield.
    function processRedemption(
        uint256 vaultId,
        address user,
        uint128 shareBalance
    )
        external
        returns (uint128 transferAmount, uint128 feeAmountDeductedFromYield);

    /// @notice Register a new vault with the adapter and snapshot the current fee on yield.
    ///
    /// Requirements:
    /// - The caller must be the SablierBob contract.
    ///
    /// @param vaultId The ID of the newly created vault.
    function registerVault(uint256 vaultId) external;

    /// @notice Sets the fee on yield for future vaults.
    ///
    /// @dev Emits a {SetYieldFee} event.
    ///
    /// Notes:
    /// - This only affects future vaults, fee is not updated for existing vaults.
    ///
    /// Requirements:
    /// - The caller must be the comptroller.
    /// - `newFee` must not exceed MAX_FEE.
    ///
    /// @param newFee The new yield fee as UD60x18 where 1e18 = 100%.
    function setYieldFee(UD60x18 newFee) external;

    /// @notice Stakes tokens deposited by a user in a vault, converting them to yield-bearing tokens.
    ///
    /// @dev Emits a {Stake} event.
    ///
    /// Requirements:
    /// - The caller must be the SablierBob contract.
    /// - The tokens must have been transferred to this contract.
    ///
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user depositing the tokens.
    /// @param amount The amount of tokens to stake.
    function stake(uint256 vaultId, address user, uint256 amount) external;

    /// @notice Converts all yield-bearing tokens in a vault back to deposit tokens after settlement.
    ///
    /// @dev Emits an {UnstakeFullAmount} event.
    ///
    /// Notes:
    /// - This should only be called once per vault after settlement.
    ///
    /// Requirements:
    /// - The caller must be the SablierBob contract.
    ///
    /// @param vaultId The ID of the vault.
    /// @return wrappedTokenBalance The total amount of yield-bearing tokens that were in the vault.
    /// @return amountReceivedFromUnstaking The total amount of tokens received from unstaking the yield-bearing tokens.
    function unstakeFullAmount(uint256 vaultId)
        external
        returns (uint128 wrappedTokenBalance, uint128 amountReceivedFromUnstaking);

    /// @notice Updates staked token balance of a user when vault shares are transferred.
    ///
    /// Requirements:
    /// - The caller must be the SablierBob contract.
    /// - `userShareBalanceBeforeTransfer` must not be zero.
    ///
    /// @param vaultId The ID of the vault.
    /// @param from The address transferring vault shares.
    /// @param to The address receiving vault shares.
    /// @param shareAmountTransferred The number of vault shares being transferred.
    /// @param userShareBalanceBeforeTransfer The sender's vault share balance before the transfer.
    function updateStakedTokenBalance(
        uint256 vaultId,
        address from,
        address to,
        uint256 shareAmountTransferred,
        uint256 userShareBalanceBeforeTransfer
    )
        external;
}
