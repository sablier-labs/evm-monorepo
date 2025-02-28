// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable no-console
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

abstract contract MaxCountScript is BaseScript {
    /// @dev The default value for `maxCountMap`.
    uint256 internal constant DEFAULT_MAX_COUNT = 500;

    /// @dev Maximum count for segments and tranches mapped by the chain Id.
    mapping(uint256 chainId => uint256 count) internal maxCountMap;

    constructor() {
        // Populate the max count map for segments and tranches.
        populateMaxCountMap();

        // If there is no maximum value set for a specific chain, use the default value.
        if (maxCountMap[block.chainid] == 0) {
            maxCountMap[block.chainid] = DEFAULT_MAX_COUNT;
        }
    }

    /// @dev Updates max values for segments and tranches. Values can be updated using the `update-counts.sh` script.
    function populateMaxCountMap() internal {
        // forgefmt: disable-start

        // Arbitrum chain ID
        maxCountMap[42161] = 1090;

        // Avalanche chain ID.
        maxCountMap[43114] = 490;

        // Base chain ID.
        maxCountMap[8453] = 2030;

        // Blast chain ID.
        maxCountMap[81457] = 1020;

        // BNB chain ID.
        maxCountMap[56] = 4460;

        // Ethereum chain ID.
        maxCountMap[1] = 1020;

        // Gnosis chain ID.
        maxCountMap[100] = 560;

        // Optimism chain ID.
        maxCountMap[10] = 1020;

        // Polygon chain ID.
        maxCountMap[137] = 1020;

        // Scroll chain ID.
        maxCountMap[534352] = 320;

        // Sepolia chain ID.
        maxCountMap[11155111] = 1020;

        // forgefmt: disable-end
    }
}
