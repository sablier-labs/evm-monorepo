// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAavePoolDataProvider } from "src/interfaces/external/IAavePoolDataProvider.sol";

/// @notice Mock Aave V3 PoolDataProvider for testing.
contract MockAavePoolDataProvider is IAavePoolDataProvider {
    mapping(address => address) private _aTokens;

    function setAToken(address asset, address aToken) external {
        _aTokens[asset] = aToken;
    }

    function getReserveTokensAddresses(address asset)
        external
        view
        override
        returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress)
    {
        return (_aTokens[asset], address(0), address(0));
    }
}
