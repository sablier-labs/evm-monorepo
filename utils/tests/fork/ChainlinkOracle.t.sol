// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { BaseScript } from "src/tests/BaseScript.sol";

import { Base_Test } from "../Base.t.sol";

contract BaseScriptMock is BaseScript { }

contract ChainlinkOracle_Fork_Test is Base_Test {
    /// @notice A modifier that runs the forked test for a given chain
    modifier initForkTest(string memory chainName) {
        // Fork chain on the latest block number.
        vm.createSelectFork({ urlOrAlias: chainName });

        BaseScriptMock baseScriptMock = new BaseScriptMock();

        // Get the Chainlink oracle address for the current chain.
        address oracle = baseScriptMock.getChainlinkOracle();

        // Retrieve the latest price and decimals from the Chainlink oracle.
        (, int256 price,, uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();
        uint8 oracleDecimals = AggregatorV3Interface(oracle).decimals();

        // Assert that the Chainlink price feed returns non-zero values.
        vm.assertGt(uint256(price), 0, "price");
        vm.assertGt(updatedAt, 0, "updated at");

        // Assert that the oracle returns 8 decimals.
        vm.assertEq(oracleDecimals, 8, "oracle decimals");

        _;
    }

    function testFork_ChainlinkOracle_Arbitrum() external initForkTest("arbitrum") { }

    function testFork_ChainlinkOracle_Avalanche() external initForkTest("avalanche") { }

    function testFork_ChainlinkOracle_Base() external initForkTest("base") { }

    function testFork_ChainlinkOracle_BSC() external initForkTest("bsc") { }

    function testFork_ChainlinkOracle_Ethereum() external initForkTest("ethereum") { }

    function testFork_ChainlinkOracle_Gnosis() external initForkTest("gnosis") { }

    function testFork_ChainlinkOracle_Linea() external initForkTest("linea") { }

    function testFork_ChainlinkOracle_Optimism() external initForkTest("optimism") { }

    function testFork_ChainlinkOracle_Polygon() external initForkTest("polygon") { }

    function testFork_ChainlinkOracle_Scroll() external initForkTest("scroll") { }
}
