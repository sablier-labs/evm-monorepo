// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { BaseScript } from "src/tests/BaseScript.sol";
import { ChainId } from "src/tests/ChainId.sol";
import { Base_Test } from "../Base.t.sol";

contract BaseScriptMock is BaseScript { }

contract ChainlinkOracle_Fork_Test is Base_Test {
    function testFork_ChainlinkOracle_Arbitrum() external {
        _testChainlinkOracle(ChainId.ARBITRUM);
    }

    function testFork_ChainlinkOracle_Avalanche() external {
        _testChainlinkOracle(ChainId.AVALANCHE);
    }

    function testFork_ChainlinkOracle_Base() external {
        _testChainlinkOracle(ChainId.BASE);
    }

    function testFork_ChainlinkOracle_BSC() external {
        _testChainlinkOracle(ChainId.BSC);
    }

    function testFork_ChainlinkOracle_Ethereum() external {
        _testChainlinkOracle(ChainId.ETHEREUM);
    }

    function testFork_ChainlinkOracle_Gnosis() external {
        _testChainlinkOracle(ChainId.GNOSIS);
    }

    function testFork_ChainlinkOracle_HyperEVM() external {
        _testChainlinkOracle(ChainId.HYPEREVM);
    }

    function testFork_ChainlinkOracle_Linea() external {
        _testChainlinkOracle(ChainId.LINEA);
    }

    /// @dev Forge cannot fork Monad from an Ethereum EVM, so this test queries the oracle over RPC instead.
    function testFork_ChainlinkOracle_Monad() external {
        vm.chainId(ChainId.MONAD);
        string memory oracle = vm.toString(new BaseScriptMock().getChainlinkOracle());

        (, int256 price,, uint256 updatedAt,) = abi.decode(
            _ethCall(oracle, AggregatorV3Interface.latestRoundData.selector), (uint80, int256, uint256, uint256, uint80)
        );
        uint8 oracleDecimals = abi.decode(_ethCall(oracle, AggregatorV3Interface.decimals.selector), (uint8));

        _assertOracleData(price, updatedAt, oracleDecimals);
    }

    function testFork_ChainlinkOracle_Optimism() external {
        _testChainlinkOracle(ChainId.OPTIMISM);
    }

    function testFork_ChainlinkOracle_Polygon() external {
        _testChainlinkOracle(ChainId.POLYGON);
    }

    function testFork_ChainlinkOracle_Scroll() external {
        _testChainlinkOracle(ChainId.SCROLL);
    }

    function testFork_ChainlinkOracle_Sonic() external {
        _testChainlinkOracle(ChainId.SONIC);
    }

    /// @dev Helper function to test Chainlink oracle for a specific chain
    function _testChainlinkOracle(uint256 chainId) private {
        // Get the chain name.
        string memory chainName = ChainId.getName(chainId);

        // Fork chain on the latest block number.
        vm.createSelectFork({ urlOrAlias: chainName });

        BaseScriptMock baseScriptMock = new BaseScriptMock();

        // Get the Chainlink oracle address for the current chain.
        address oracle = baseScriptMock.getChainlinkOracle();

        // Skip if oracle is not found.
        if (oracle == address(0)) return;

        // Retrieve the latest price and decimals from the Chainlink oracle.
        (, int256 price,, uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();
        uint8 oracleDecimals = AggregatorV3Interface(oracle).decimals();

        _assertOracleData(price, updatedAt, oracleDecimals);
    }

    function _assertOracleData(int256 price, uint256 updatedAt, uint8 oracleDecimals) private pure {
        // It should return non-zero values from the Chainlink price feed.
        vm.assertGt(uint256(price), 0, "price");
        vm.assertGt(updatedAt, 0, "updated at");

        // It should return 8 decimals from the oracle.
        vm.assertEq(oracleDecimals, 8, "oracle decimals");
    }

    /// @dev Calls a no-argument function on the Monad contract at `to` and returns the raw result.
    function _ethCall(string memory to, bytes4 selector) private returns (bytes memory) {
        string memory params = string.concat(
            "[{\"to\":\"", to, "\",\"data\":\"", vm.toString(abi.encodePacked(selector)), "\"},\"latest\"]"
        );
        return vm.rpc({ urlOrAlias: "monad", method: "eth_call", params: params });
    }
}
