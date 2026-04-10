// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAavePool } from "src/interfaces/external/IAavePool.sol";

import { MockAaveAToken } from "./MockAaveAToken.sol";

/// @notice Mock Aave V3 Pool for testing supply and withdraw flows.
contract MockAavePool is IAavePool {
    uint256 private constant RAY = 1e27;

    MockAaveAToken public aToken;
    uint256 private _normalizedIncome = RAY;

    constructor(address aToken_) {
        aToken = MockAaveAToken(aToken_);
    }

    function getReserveNormalizedIncome(address) external view override returns (uint256) {
        return _normalizedIncome;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external override {
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        uint256 scaledAmount = amount * RAY / _normalizedIncome;
        aToken.mint(onBehalfOf, scaledAmount);
    }

    function withdraw(address asset, uint256 amount, address to) external override returns (uint256) {
        uint256 scaledAmount = amount * RAY / _normalizedIncome;
        aToken.burn(msg.sender, scaledAmount);
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    function setNormalizedIncome(uint256 newIncome) external {
        _normalizedIncome = newIncome;
        aToken.setNormalizedIncome(newIncome);
    }
}
