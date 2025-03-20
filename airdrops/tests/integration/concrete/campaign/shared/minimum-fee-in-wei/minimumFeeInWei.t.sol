// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import {
    ChainlinkOracleOutdated,
    ChainlinkOracleFuture,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWith6Decimals,
    ChainlinkOracleZeroPrice
} from "tests/utils/ChainlinkMocks.sol";
import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract MinimumFeeInWei_Integration_Test is Integration_Test {
    function setUp() public virtual override {
        // Make admin the caller for this test suite.
        resetPrank(users.admin);
    }

    function test_GivenOracleZero() external {
        // Deploy campaign with zero oracle address.
        merkleFactoryBase.setOracle(address(0));
        _deployCampaign();

        // It should return zero.
        assertEq(merkleBase.minimumFeeInWei(), 0, "minimum fee in wei");
    }

    function test_GivenMinimumFeeZero() external givenOracleNotZero {
        // Deploy campaign with zero minimum fee.
        merkleFactoryBase.setMinimumFee(0);
        _deployCampaign();

        // It should return zero.
        assertEq(merkleBase.minimumFeeInWei(), 0, "minimum fee in wei");
    }

    function test_WhenOracleUpdatedTimeInFuture() external givenOracleNotZero givenMinimumFeeNotZero {
        // Deploy campaign with an oracle that has `updatedAt` timestamp in the future.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleFuture()));
        _deployCampaign();

        // It should return zero.
        assertEq(merkleBase.minimumFeeInWei(), 0, "minimum fee in wei");
    }

    function test_WhenOraclePriceOutdated()
        external
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleUpdatedTimeNotInFuture
    {
        // Deploy campaign with an oracle that has `updatedAt` timestamp older than 24 hours.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleOutdated()));
        _deployCampaign();

        // It should return zero.
        assertEq(merkleBase.minimumFeeInWei(), 0, "minimum fee in wei");
    }

    function test_WhenOraclePriceZero()
        external
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
    {
        // Deploy campaign with with an oracle that returns 0 price.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleZeroPrice()));
        _deployCampaign();

        // It should return zero.
        assertEq(merkleBase.minimumFeeInWei(), 0, "minimum fee in wei");
    }

    function test_WhenOraclePriceHasEightDecimals()
        external
        view
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        // It should calculate the minimum fee in wei.
        assertEq(merkleBase.minimumFeeInWei(), MINIMUM_FEE_IN_WEI, "minimum fee in wei");
    }

    function test_WhenOraclePriceHasMoreThanEightDecimals()
        external
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        // Deploy campaign with an oracle that returns 18 decimals.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleWith18Decimals()));
        _deployCampaign();

        // It should calculate the minimum fee in wei.
        assertEq(merkleBase.minimumFeeInWei(), MINIMUM_FEE_IN_WEI, "minimum fee in wei");
    }

    function test_WhenOraclePriceHasLessThanEightDecimals()
        external
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        // Deploy campaign with an oracle that returns 6 decimals.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleWith6Decimals()));
        _deployCampaign();

        // It should calculate the minimum fee in wei.
        assertEq(merkleBase.minimumFeeInWei(), MINIMUM_FEE_IN_WEI, "minimum fee in wei");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   HELPER FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A helper function to deploy campaign with given oracle address and minimum fee.
    function _deployCampaign() private {
        if (Strings.equal(campaignType, "instant")) {
            merkleBase = createMerkleInstant();
        } else if (Strings.equal(campaignType, "ll")) {
            merkleBase = createMerkleLL();
        } else if (Strings.equal(campaignType, "lt")) {
            merkleBase = createMerkleLT();
        } else if (Strings.equal(campaignType, "vca")) {
            merkleBase = createMerkleVCA();
        } else {
            revert("Invalid campaign type");
        }
    }
}
