// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import {
    ChainlinkOracleMockWith18Decimals,
    ChainlinkOracleMockWith6Decimals,
    ChainlinkOracleMockWithZeroPrice
} from "tests/utils/ChainlinkOracleMock.sol";
import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract MinimumFeeInWei_Integration_Test is Integration_Test {
    string private _campaignType;

    constructor(string memory campaignType) {
        _campaignType = campaignType;
    }

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

    function test_WhenOracleReturnsZeroPrice() external givenOracleNotZero givenMinimumFeeNotZero {
        // Deploy campaign with with an oracle that returns 0 price.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleMockWithZeroPrice()));
        _deployCampaign();

        // It should return zero.
        assertEq(merkleBase.minimumFeeInWei(), 0, "minimum fee in wei");
    }

    function test_WhenOracleReturnsEightDecimals()
        external
        view
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleReturnsNonZeroPrice
    {
        // It should calculate the minimum fee in wei.
        assertEq(merkleBase.minimumFeeInWei(), MINIMUM_FEE_IN_WEI, "minimum fee in wei");
    }

    function test_WhenOracleReturnsMoreThanEightDecimals()
        external
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleReturnsNonZeroPrice
    {
        // Deploy campaign with an oracle that returns 18 decimals.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleMockWith18Decimals()));
        _deployCampaign();

        // It should calculate the minimum fee in wei.
        assertEq(merkleBase.minimumFeeInWei(), MINIMUM_FEE_IN_WEI, "minimum fee in wei");
    }

    function test_WhenOracleReturnsLessThanEightDecimals()
        external
        givenOracleNotZero
        givenMinimumFeeNotZero
        whenOracleReturnsNonZeroPrice
    {
        // Deploy campaign with an oracle that returns 6 decimals.
        merkleFactoryBase.setOracle(address(new ChainlinkOracleMockWith6Decimals()));
        _deployCampaign();

        // It should calculate the minimum fee in wei.
        assertEq(merkleBase.minimumFeeInWei(), MINIMUM_FEE_IN_WEI, "minimum fee in wei");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   HELPER FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A helper function to deploy campaign with given oracle address and minimum fee.
    function _deployCampaign() private {
        if (Strings.equal(_campaignType, "instant")) {
            merkleBase = createMerkleInstant();
        } else if (Strings.equal(_campaignType, "ll")) {
            merkleBase = createMerkleLL();
        } else if (Strings.equal(_campaignType, "lt")) {
            merkleBase = createMerkleLT();
        } else if (Strings.equal(_campaignType, "vca")) {
            merkleBase = createMerkleVCA();
        } else {
            revert("Invalid campaign type");
        }
    }
}
