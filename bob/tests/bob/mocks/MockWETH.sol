// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";

/// @notice Mock WETH wrapper contract.
contract MockWETH is ERC20, IWETH9 {
    constructor() ERC20("Wrapped Ether", "WETH") { }

    function deposit() external payable override {
        _mint(msg.sender, msg.value);
    }

    /// @dev Overrides to match WETH9 behavior: skip allowance check when `src == msg.sender`.
    function transferFrom(address src, address dst, uint256 wad) public override(ERC20, IERC20) returns (bool) {
        if (src != msg.sender) {
            _spendAllowance(src, msg.sender, wad);
        }
        _transfer(src, dst, wad);
        return true;
    }

    function withdraw(uint256 amount) external override {
        _burn(msg.sender, amount);
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }
}
