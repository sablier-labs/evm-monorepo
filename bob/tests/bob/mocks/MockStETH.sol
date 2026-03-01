// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IStETH } from "src/interfaces/external/IStETH.sol";

/// @notice Mock stETH token contract.
contract MockStETH is ERC20, IStETH {
    constructor() ERC20("Liquid staked Ether 2.0", "stETH") { }

    function submit(address) external payable override returns (uint256) {
        _mint(msg.sender, msg.value);
        return msg.value;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    receive() external payable {
        _mint(msg.sender, msg.value);
    }
}
