// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Allows anyone to mint or burn any amount of tokens to any account.
contract SablierERC20Faucet is ERC20("SablierERC20Faucet", "SAB-ERC20") {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event Burn(address indexed account, uint256 value);

    event Mint(address indexed account, uint256 value);

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Burns `value` tokens from `account`, reducing the token supply.
    /// @param account The address whose tokens will be burned.
    /// @param value The amount of tokens to burn.
    function burn(address account, uint256 value) public {
        _burn(account, value);
    }

    /// @notice Mints `value` new tokens and assigns them to `account`, increasing the total supply.
    /// @param account The address to receive the newly minted tokens.
    /// @param value The amount of tokens to mint.
    function mint(address account, uint256 value) public {
        require(balanceOf(account) <= 10_000_000e18, "dont be greedy");
        _mint(account, value);
    }
}
