// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @dev By default, Chainlink uses 8 decimals for non-ETH pairs: https://ethereum.stackexchange.com/q/92508/24693
uint8 constant DEFAULT_DECIMALS = 8;

/*//////////////////////////////////////////////////////////////////////////
                           NON-REVERTING-ORACLES
//////////////////////////////////////////////////////////////////////////*/

/// @notice A mock Chainlink oracle that returns a $3000 price with 8 decimals.
contract ChainlinkOracleMock {
    function decimals() external pure returns (uint8) {
        return DEFAULT_DECIMALS;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 answer_ = 3000e8;
        uint256 updatedAt_ = block.timestamp;
        return (0, answer_, 0, updatedAt_, 0);
    }
}

/// @notice A mock Chainlink oracle with `updatedAt` timestamp in the future.
contract ChainlinkOracleFutureDatedPrice {
    function decimals() external pure returns (uint8) {
        return DEFAULT_DECIMALS;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 answer_ = 3000e8;
        uint256 updatedAt_ = block.timestamp + 1 seconds;
        return (0, answer_, 0, updatedAt_, 0);
    }
}

contract ChainlinkOracleNegativePrice {
    function decimals() external pure returns (uint8) {
        return DEFAULT_DECIMALS;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 answer_ = -3000e8; // Negative price
        uint256 updatedAt_ = block.timestamp;
        return (0, answer_, 0, updatedAt_, 0);
    }
}

/// @notice A mock Chainlink oracle that was updated more than 24 hours ago.
contract ChainlinkOracleOutdatedPrice {
    function decimals() external pure returns (uint8) {
        return DEFAULT_DECIMALS;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 answer_ = 3000e8;
        uint256 delta = 24 hours + 2 seconds;
        uint256 updatedAt_ = block.timestamp - delta;
        return (0, answer_, 0, updatedAt_, 0);
    }
}

/// @notice A mock Chainlink oracle that returns a $3000 price with 18 decimals.
contract ChainlinkOracleWith18Decimals {
    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 answer_ = 3000e18;
        uint256 updatedAt_ = block.timestamp;
        return (0, answer_, 0, updatedAt_, 0);
    }
}

/// @notice A mock Chainlink oracle that returns $3000 price with 6 decimals.
contract ChainlinkOracleWith6Decimals {
    function decimals() external pure returns (uint8) {
        return 6;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 answer_ = 3000e6;
        uint256 updatedAt_ = block.timestamp;
        return (0, answer_, 0, updatedAt_, 0);
    }
}

/// @notice A mock Chainlink oracle that returns 0 as a price.
contract ChainlinkOracleZeroPrice {
    function decimals() external pure returns (uint8) {
        return DEFAULT_DECIMALS;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint256 updatedAt_ = block.timestamp;
        return (0, 0, 0, updatedAt_, 0);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                             REVERTING-ORACLES
//////////////////////////////////////////////////////////////////////////*/

/// @notice A mock Chainlink oracle that reverts when `decimals` is called.
contract ChainlinkOracleWithRevertingDecimals {
    function decimals() external pure returns (uint8) {
        revert("Not gonna happen");
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        int256 answer_ = 3000e8;
        uint256 updatedAt_ = block.timestamp;
        return (0, answer_, 0, updatedAt_, 0);
    }
}

/// @notice A mock Chainlink oracle that reverts when `latestRoundData` is called.
contract ChainlinkOracleWithRevertingPrice {
    function decimals() external pure returns (uint8) {
        return DEFAULT_DECIMALS;
    }

    function latestRoundData() external pure returns (uint80, int256, uint256, uint256, uint80) {
        revert("Not gonna happen");
    }
}
