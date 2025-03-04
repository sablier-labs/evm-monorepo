// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable code-complexity
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript as EvmUtilsBaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

abstract contract BaseScript is EvmUtilsBaseScript {
    /// @notice Returns the Chainlink oracle for the supported chains. These addresses can be verified on
    /// https://docs.chain.link/data-feeds/price-feeds/addresses.
    /// @dev If the chain does not have a Chainlink oracle, return 0.
    function chainlinkOracle() public view returns (address addr) {
        // Ethereum Mainnet
        if (block.chainid == 1) return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        // Arbitrum One
        if (block.chainid == 42_161) return 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        // Avalanche
        if (block.chainid == 43_114) return 0x0A77230d17318075983913bC2145DB16C7366156;
        // Base
        if (block.chainid == 8453) return 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        // BNB Smart Chain
        if (block.chainid == 56) return 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        // Gnosis Chain
        if (block.chainid == 100) return 0x678df3415fc31947dA4324eC63212874be5a82f8;
        // Linea
        if (block.chainid == 59_144) return 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        // Optimism
        if (block.chainid == 10) return 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        // Polygon
        if (block.chainid == 137) return 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        // Scroll
        if (block.chainid == 534_352) return 0x6bF14CB0A831078629D993FDeBcB182b21A8774C;

        // Return address zero for unsupported chain.
        return address(0);
    }

    /// @notice Returns the initial minimum fee as $1. If the chain does not have a Chainlink oracle, return 0.
    function initialMinimumFee() public view returns (uint256 fee) {
        if (chainlinkOracle() != address(0)) return 1e8;

        // Return 0 for chains without Chainlink oracle.
        return 0;
    }
}
