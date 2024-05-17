// solhint-disable no-console
pragma solidity >=0.8.22 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";
import { Test } from "forge-std/src/Test.sol";

import { LockupDynamic_Gas_Test } from "./LockupDynamic.Gas.t.sol";
import { LockupTranched_Gas_Test } from "./LockupTranched.Gas.t.sol";

/// @notice Structure to group the block gas limit and chain id.
struct ChainInfo {
    uint256 blockGasLimit;
    uint256 chainId;
}

contract EstimateMaxCount is Test {
    // Buffer gas units to be deducted from the block gas limit so that the max count never exceeds the block limit.
    uint256 public constant BUFFER_GAS = 1_000_000;

    // Initial guess for the maximum number of segments/tranches.
    uint128 public constant INITIAL_GUESS = 240;

    /// @dev List of chains with their block gas limit.
    ChainInfo[] public chains;

    constructor() {
        chains.push(ChainInfo({ blockGasLimit: 32_000_000, chainId: 42_161 })); // Arbitrum
        chains.push(ChainInfo({ blockGasLimit: 15_000_000, chainId: 43_114 })); // Avalanche
        chains.push(ChainInfo({ blockGasLimit: 60_000_000, chainId: 8453 })); // Base
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 238 })); // Blast
        chains.push(ChainInfo({ blockGasLimit: 138_000_000, chainId: 56 })); // BNB
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 1 })); // Ethereum
        chains.push(ChainInfo({ blockGasLimit: 17_000_000, chainId: 100 })); // Gnosis
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 10 })); // Optimism
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 137 })); // Polygon
        chains.push(ChainInfo({ blockGasLimit: 10_000_000, chainId: 534_352 })); // Scroll
        chains.push(ChainInfo({ blockGasLimit: 30_000_000, chainId: 11_155_111 })); // Sepolia
    }

    /// @notice Estimate the maximum number of segments allowed in LockupDynamic.
    function test_EstimateSegments() public {
        LockupDynamic_Gas_Test lockupDynamicGasTest = new LockupDynamic_Gas_Test();
        lockupDynamicGasTest.setUp();

        for (uint256 i = 0; i < chains.length; ++i) {
            uint128 count = INITIAL_GUESS;

            // Subtract `BUFFER_GAS` from `blockGasLimit` as an additional precaution to account for the dynamic gas for
            // ether transfer on different chains.
            uint256 blockGasLimit = chains[i].blockGasLimit - BUFFER_GAS;

            uint256 gasConsumed = 0;
            uint256 lastGasConsumed = 0;
            while (blockGasLimit > gasConsumed) {
                count += 10;
                lastGasConsumed = gasConsumed;

                // Estimate the gas consumed by adding 10 segments.
                gasConsumed = lockupDynamicGasTest.computeGas_CreateWithDurations(count + 10);
            }

            console2.log("count: %d and gasUsed: %d and chainId: %d", count, lastGasConsumed, chains[i].chainId);
        }
    }

    /// @notice Estimate the maximum number of tranches allowed in LockupTranched.
    function test_EstimateTranches() public {
        LockupTranched_Gas_Test lockupTranchedGasTest = new LockupTranched_Gas_Test();
        lockupTranchedGasTest.setUp();

        for (uint256 i = 0; i < chains.length; ++i) {
            uint128 count = INITIAL_GUESS;

            // Subtract `BUFFER_GAS` from `blockGasLimit` as an additional precaution to account for the dynamic gas for
            // ether transfer on different chains.
            uint256 blockGasLimit = chains[i].blockGasLimit - BUFFER_GAS;

            uint256 gasConsumed = 0;
            uint256 lastGasConsumed = 0;
            while (blockGasLimit > gasConsumed) {
                count += 10;
                lastGasConsumed = gasConsumed;

                // Estimate the gas consumed by adding 10 tranches.
                gasConsumed = lockupTranchedGasTest.computeGas_CreateWithDurations(count + 10);
            }

            console2.log("count: %d and gasUsed: %d and chainId: %d", count, lastGasConsumed, chains[i].chainId);
        }
    }
}
