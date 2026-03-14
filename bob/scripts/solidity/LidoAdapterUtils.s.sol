// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ChainId } from "@sablier/evm-utils/src/tests/ChainId.sol";

/// @notice Lido Adapter utility functions for deploy scripts.
abstract contract LidoAdapterUtils {
    UD60x18 internal constant INITIAL_SLIPPAGE_TOLERANCE = UD60x18.wrap(0.005e18); // 0.5%
    UD60x18 internal constant INITIAL_YIELD_FEE = UD60x18.wrap(0.1e18); // 10%

    function getCurvePool() internal view returns (address curvePool) {
        if (block.chainid == ChainId.ETHEREUM) {
            curvePool = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022;
        } else if (block.chainid == ChainId.SEPOLIA) {
            // Dummy since there is no Curve pool on Sepolia.
            curvePool = address(1);
        }
    }

    function getLidoWithdrawalQueue() internal view returns (address lidoWithdrawalQueue) {
        if (block.chainid == ChainId.ETHEREUM) {
            // https://docs.lido.fi/deployed-contracts/
            lidoWithdrawalQueue = 0x889edC2eDab5f40e902b864aD4d7AdE8E412F9B1;
        } else if (block.chainid == ChainId.SEPOLIA) {
            // https://docs.lido.fi/deployed-contracts/sepolia#core-protocol
            lidoWithdrawalQueue = 0x1583C7b3f4C3B008720E6BcE5726336b0aB25fdd;
        }
    }

    function getSteth() internal view returns (address steth) {
        if (block.chainid == ChainId.ETHEREUM) {
            steth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        } else if (block.chainid == ChainId.SEPOLIA) {
            steth = 0x3e3FE7dBc6B4C189E7128855dD526361c49b40Af;
        }
    }

    function getStethEthOracle() internal view returns (address stethEthOracle) {
        if (block.chainid == ChainId.ETHEREUM) {
            // Chainlink stETH/ETH feed on mainnet.
            stethEthOracle = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;
        } else if (block.chainid == ChainId.SEPOLIA) {
            // Dummy since there is no stETH/ETH feed on Sepolia.
        }
    }

    function getWeth() internal view returns (address weth) {
        if (block.chainid == ChainId.ETHEREUM) {
            weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        } else if (block.chainid == ChainId.SEPOLIA) {
            weth = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
        }
    }

    function getWsteth() internal view returns (address wsteth) {
        if (block.chainid == ChainId.ETHEREUM) {
            wsteth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
        } else if (block.chainid == ChainId.SEPOLIA) {
            wsteth = 0xB82381A3fBD3FaFA77B3a7bE693342618240067b;
        }
    }
}
