// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAaveToken } from "src/interfaces/external/IAaveToken.sol";

/// @notice Mock Aave V3 aToken with configurable scaled balance tracking.
contract MockAaveAToken is IAaveToken {
    uint256 private constant RAY = 1e27;

    mapping(address => uint256) private _scaledBalances;
    address public pool;
    uint256 public normalizedIncome = RAY;

    function setPool(address pool_) external {
        pool = pool_;
    }

    function setNormalizedIncome(uint256 newIncome) external {
        normalizedIncome = newIncome;
    }

    function scaledBalanceOf(address user) external view override returns (uint256) {
        return _scaledBalances[user];
    }

    function balanceOf(address user) external view override returns (uint256) {
        return _scaledBalances[user] * normalizedIncome / RAY;
    }

    function mint(address user, uint256 scaledAmount) external {
        require(msg.sender == pool, "MockAaveAToken: only pool");
        _scaledBalances[user] += scaledAmount;
    }

    function burn(address user, uint256 scaledAmount) external {
        require(msg.sender == pool, "MockAaveAToken: only pool");
        _scaledBalances[user] -= scaledAmount;
    }
}
