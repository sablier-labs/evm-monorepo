// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAavePoolAddressesProvider } from "src/interfaces/external/IAavePoolAddressesProvider.sol";

/// @notice Mock Aave V3 PoolAddressesProvider for testing.
contract MockAavePoolAddressesProvider is IAavePoolAddressesProvider {
    address private _pool;
    address private _poolDataProvider;

    constructor(address pool_, address poolDataProvider_) {
        _pool = pool_;
        _poolDataProvider = poolDataProvider_;
    }

    function getPool() external view override returns (address) {
        return _pool;
    }

    function getPoolDataProvider() external view override returns (address) {
        return _poolDataProvider;
    }
}
