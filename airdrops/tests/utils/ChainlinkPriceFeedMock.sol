// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @notice A mock Chainlink price feed contract that returns a constant price of $3000 for 1 native token.
contract ChainlinkPriceFeedMock {
    int256 private constant THREE_THOUSAND = 3000e8; // Chainlink format price (8 decimals)

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, THREE_THOUSAND, 0, 0, 0);
    }
}

/// @notice A mock Chainlink price feed that does not implement the `latestRoundData` function.
contract ChainlinkPriceFeedMock_Empty { }
