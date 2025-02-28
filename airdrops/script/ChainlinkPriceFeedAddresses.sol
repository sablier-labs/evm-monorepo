// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice A contract that stores the Chainlink price feed addresses for the supported chains.
/// @dev The actual addresses can be found at: https://docs.chain.link/data-feeds/price-feeds/addresses
contract ChainlinkPriceFeedAddresses {
    mapping(uint256 chaindId => address oracle) private _priceFeeds;

    /// @dev Populate the price feeds for the supported chains.
    constructor() {
        // Ethereum Mainnet
        _priceFeeds[1] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        // Arbitrum One
        _priceFeeds[42_161] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;
        // Avalanche
        _priceFeeds[43_114] = 0x0A77230d17318075983913bC2145DB16C7366156;
        // Base
        _priceFeeds[8453] = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
        // BNB Smart Chain
        _priceFeeds[56] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        // Gnosis Chain
        _priceFeeds[100] = 0x678df3415fc31947dA4324eC63212874be5a82f8;
        // Linea
        _priceFeeds[59_144] = 0x3c6Cd9Cc7c7a4c2Cf5a82734CD249D7D593354dA;
        // Optimism
        _priceFeeds[10] = 0x13e3Ee699D1909E989722E753853AE30b17e08c5;
        // Polygon
        _priceFeeds[137] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        // Scroll
        _priceFeeds[534_352] = 0x6bF14CB0A831078629D993FDeBcB182b21A8774C;
        // zkSync Era
        _priceFeeds[324] = 0x6D41d1dc818112880b40e26BD6FD347E41008eDA;
    }

    function getPriceFeedAddress() public view returns (address) {
        return _priceFeeds[block.chainid];
    }
}
