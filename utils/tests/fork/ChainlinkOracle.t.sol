// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdAssertions } from "forge-std/src/StdAssertions.sol";

import { BaseScript } from "src/tests/BaseScript.sol";
import { BaseTest } from "src/tests/BaseTest.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";

contract ChainlinkOracle_Fork_Test is BaseScript, BaseTest, StdAssertions {
    /// @notice A modifier that runs the forked test for a given chain
    modifier initForkTest(string memory chainName) {
        // Fork chain on the latest block number.
        vm.createSelectFork({ urlOrAlias: chainName });

        // Deploy the Merkle Instant factory and create a new campaign.
        comptroller = new SablierComptroller(
            admin, getInitialMinFeeUSD(), getInitialMinFeeUSD(), getInitialMinFeeUSD(), getChainlinkOracle()
        );

        // It should return non-zero values for the min fees.
        assertGt(comptroller.calculateAirdropsMinFeeWei(), 0, "airdrop");
        assertGt(comptroller.calculateFlowMinFeeWei(), 0, "flow");
        assertGt(comptroller.calculateLockupMinFeeWei(), 0, "lockup");

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

    function testFork_ChainlinkOracle_Zksync() external initForkTest("zksync") { }
}
