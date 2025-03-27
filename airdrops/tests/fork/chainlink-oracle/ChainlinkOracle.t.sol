// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "script/Base.sol";
import { SablierFactoryMerkleInstant } from "src/SablierFactoryMerkleInstant.sol";

import { Base_Test } from "./../../Base.t.sol";

contract ChainlinkOracle_Fork_Test is BaseScript, Base_Test {
    /// @notice A modifier that runs the forked test for a given chain
    modifier initForkTest(string memory chainName) {
        // Fork chain on the latest block number.
        vm.createSelectFork({ urlOrAlias: chainName });

        // Deploy the Merkle Instant factory and create a new campaign.
        factoryMerkleInstant = new SablierFactoryMerkleInstant(users.admin, initialMinFeeUSD(), chainlinkOracle());
        merkleInstant = factoryMerkleInstant.createMerkleInstant(
            merkleInstantConstructorParams(), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );

        // Assert that the Chainlink returns a non-zero price by checking the value of min fee in wei.
        assertLt(0, merkleInstant.calculateMinFeeWei(), "min fee wei");

        _;
    }

    function testFork_ChainlinkOracle_Mainnet() external initForkTest("mainnet") { }

    function testFork_ChainlinkOracle_Arbitrum() external initForkTest("arbitrum") { }

    function testFork_ChainlinkOracle_Avalanche() external initForkTest("avalanche") { }

    function testFork_ChainlinkOracle_Base() external initForkTest("base") { }

    // function testFork_ChainlinkOracle_BNB() external initForkTest("bnb") { }

    function testFork_ChainlinkOracle_Gnosis() external initForkTest("gnosis") { }

    function testFork_ChainlinkOracle_Linea() external initForkTest("linea") { }

    function testFork_ChainlinkOracle_Optimism() external initForkTest("optimism") { }

    function testFork_ChainlinkOracle_Polygon() external initForkTest("polygon") { }

    function testFork_ChainlinkOracle_Scroll() external initForkTest("scroll") { }
}
