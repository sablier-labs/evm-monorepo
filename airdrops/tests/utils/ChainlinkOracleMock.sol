// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @notice A mock Chainlink oracle contract that returns $3000 price with 8 decimals.
contract ChainlinkOracleMock {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e8, 0, 0, 0);
    }
}

/// @notice A mock Chainlink oracle that does not implement the `latestRoundData` function.
contract ChainlinkOracleWithoutImpl { }

/// @notice A mock Chainlink oracle contract that returns $3000 price with 18 decimals.
contract ChainlinkOracleMockWith18Decimals {
    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e18, 0, 0, 0);
    }
}

/// @notice A mock Chainlink oracle contract that returns $3000 price with 6 decimals.
contract ChainlinkOracleMockWith6Decimals {
    function decimals() external pure returns (uint8) {
        return 6;
    }

    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 3000e6, 0, 0, 0);
    }
}

/// @notice A mock Chainlink oracle contract that returns a 0 price.
contract ChainlinkOracleMockWithZeroPrice {
    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestRoundData()
        external
        pure
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, 0, 0, 0, 0);
    }
}
