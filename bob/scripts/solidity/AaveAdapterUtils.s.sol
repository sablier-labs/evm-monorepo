// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ChainId } from "@sablier/evm-utils/src/tests/ChainId.sol";

/// @notice Aave Adapter utility functions for deploy scripts.
abstract contract AaveAdapterUtils {
    UD60x18 internal constant INITIAL_YIELD_FEE = UD60x18.wrap(0.1e18); // 10%

    /// @dev Returns the Aave V3 PoolAddressesProvider for the current chain.
    /// See https://aave.com/docs/resources/addresses
    function getAavePoolAddressesProvider() internal view returns (address aavePoolAddressesProvider) {
        if (block.chainid == ChainId.ETHEREUM) {
            aavePoolAddressesProvider = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
        } else if (block.chainid == ChainId.SEPOLIA) {
            aavePoolAddressesProvider = 0x012bAC54348C0E635dCAc9D5FB99f06F24136C9A;
        }
    }
}
