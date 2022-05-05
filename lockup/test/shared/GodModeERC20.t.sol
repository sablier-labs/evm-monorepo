// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import "@prb/contracts/token/erc20/ERC20.sol";

/// @title GodModeERC20
/// @author Sablier Labs Ltd.
/// @notice An ERC-20 token contract that allow anyone to mint or burn any amount of tokens to or from any account.
/// @dev Strictly for test purposes.
contract GodModeERC20 is ERC20 {
    /// EVENTS ///

    event Burn(address indexed holder, uint256 burnAmount);

    event Mint(address indexed beneficiary, uint256 mintAmount);

    /// CONSTRUCTOR ///

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_, decimals_) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @notice Destroys `burnAmount` tokens from `holder`, reducing the token supply.
    /// @param holder The account whose tokens to burn.
    /// @param burnAmount The amount of tokens to destroy.
    function burn(address holder, uint256 burnAmount) external {
        burnInternal(holder, burnAmount);
    }

    /// @notice Prints new tokens into existence and assigns them to `beneficiary`, increasing the total supply.
    /// @param beneficiary The account for which to mint the tokens.
    /// @param mintAmount The amount of tokens to print into existence.
    function mint(address beneficiary, uint256 mintAmount) external {
        mintInternal(beneficiary, mintAmount);
    }
}
