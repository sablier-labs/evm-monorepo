// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ChainlinkPriceFeedAddresses } from "script/ChainlinkPriceFeedAddresses.sol";
import { SablierMerkleFactoryInstant } from "src/SablierMerkleFactoryInstant.sol";

import { Base_Test } from "./../../Base.t.sol";

contract ChainlinkPriceFeed_ForkTest is Base_Test, ChainlinkPriceFeedAddresses {
    struct ForkData {
        uint256 blockNumber;
        uint256 nativeTokenPrice;
    }

    mapping(string chainName => ForkData forkData) internal _forkData;

    function setUp() public override {
        _forkData["mainnet"] = ForkData({ blockNumber: 21_747_949, nativeTokenPrice: 3296.39063484e8 });
        _forkData["arbitrum"] = ForkData({ blockNumber: 301_342_102, nativeTokenPrice: 3296.39063484e8 });
        _forkData["avalanche"] = ForkData({ blockNumber: 56_638_766, nativeTokenPrice: 34.40327525e8 });
        _forkData["base"] = ForkData({ blockNumber: 25_789_326, nativeTokenPrice: 3296.39063484e8 });
        _forkData["bnb"] = ForkData({ blockNumber: 46_262_221, nativeTokenPrice: 677.11242076e8 });
        _forkData["gnosis"] = ForkData({ blockNumber: 38_330_311, nativeTokenPrice: 1e8 });
        _forkData["linea"] = ForkData({ blockNumber: 15_278_290, nativeTokenPrice: 3296.39063484e8 });
        _forkData["optimism"] = ForkData({ blockNumber: 131_384_611, nativeTokenPrice: 3296.39063484e8 });
        _forkData["polygon"] = ForkData({ blockNumber: 67_387_132, nativeTokenPrice: 0.40694339e8 });
        _forkData["scroll"] = ForkData({ blockNumber: 13_108_201, nativeTokenPrice: 3296.39063484e8 });
    }

    /// @dev We need to re-deploy the contracts on each forked chain.
    modifier initTest(string memory chainName) {
        vm.createSelectFork({ urlOrAlias: chainName, blockNumber: _forkData[chainName].blockNumber });
        merkleFactoryInstant = new SablierMerkleFactoryInstant(users.admin, MINIMUM_FEE, getPriceFeedAddress());
        merkleInstant = merkleFactoryInstant.createMerkleInstant(
            merkleInstantConstructorParams(), AGGREGATE_AMOUNT, RECIPIENT_COUNT
        );
        _;
    }

    function testFork_PriceFeed_Mainnet() external initTest("mainnet") {
        _test_PriceFeed("mainnet");
    }

    function testFork_PriceFeed_Arbitrum() external initTest("arbitrum") {
        _test_PriceFeed("arbitrum");
    }

    function testFork_PriceFeed_Avalanche() external initTest("avalanche") {
        _test_PriceFeed("avalanche");
    }

    function testFork_PriceFeed_Base() external initTest("base") {
        _test_PriceFeed("base");
    }

    function testFork_PriceFeed_BNB() external initTest("bnb") {
        _test_PriceFeed("bnb");
    }

    function testFork_PriceFeed_Gnosis() external initTest("gnosis") {
        _test_PriceFeed("gnosis");
    }

    function testFork_PriceFeed_Linea() external initTest("linea") {
        _test_PriceFeed("linea");
    }

    function testFork_PriceFeed_Optimism() external initTest("optimism") {
        _test_PriceFeed("optimism");
    }

    function testFork_PriceFeed_Polygon() external initTest("polygon") {
        _test_PriceFeed("polygon");
    }

    function testFork_PriceFeed_Scroll() external initTest("scroll") {
        _test_PriceFeed("scroll");
    }

    function _test_PriceFeed(string memory chainName) private view {
        uint256 expectedFeeInWei = 1e18 * MINIMUM_FEE / _forkData[chainName].nativeTokenPrice;
        uint256 actualFeeInWei = merkleInstant.minimumFeeInWei();

        // Assert the actual fee in wei is within 2% of the expected fee in wei.
        uint256 tolerance = actualFeeInWei * 20 / 1000;
        assertApproxEqAbs(actualFeeInWei, expectedFeeInWei, tolerance, "fee");
    }
}
