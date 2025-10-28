// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { BaseScript } from "src/tests/BaseScript.sol";
import { ChainId } from "src/tests/ChainId.sol";
import { Base_Test } from "../Base.t.sol";

contract BaseScriptMock is BaseScript { }

contract ChainlinkOracle_Fork_Test is Base_Test {
    function testFork_ChainlinkOracle() external {
        // Get list of mainnet chain IDs.
        uint256[] memory supportedChainIds = ChainId.getAllMainnets();

        // Run tests over all supported chains.
        for (uint256 i = 0; i < 26; ++i) {
            uint256 chainId = supportedChainIds[i];

            // Skip zksync as it requires a different foundry version.
            if (chainId == ChainId.ZKSYNC) continue;

            // Get the chain name.
            string memory chainName = ChainId.getName(chainId);

            // Fork chain on the latest block number.
            vm.createSelectFork({ urlOrAlias: chainName });

            BaseScriptMock baseScriptMock = new BaseScriptMock();

            // Get the Chainlink oracle address for the current chain.
            address oracle = baseScriptMock.getChainlinkOracle();

            // Skip if oracle is not found.
            if (oracle == address(0)) continue;

            // Retrieve the latest price and decimals from the Chainlink oracle.
            (, int256 price,, uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();
            uint8 oracleDecimals = AggregatorV3Interface(oracle).decimals();

            // Assert that the Chainlink price feed returns non-zero values.
            vm.assertGt(uint256(price), 0, "price");
            vm.assertGt(updatedAt, 0, "updated at");

            // Assert that the oracle returns 8 decimals.
            vm.assertEq(oracleDecimals, 8, "oracle decimals");
        }
    }
}
