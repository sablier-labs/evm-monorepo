// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";

import { Integration_Test } from "./../../../Integration.t.sol";
import { CalculateMinFeeWei_Integration_Test } from "./../shared/calculate-min-fee-wei/calculateMinFeeWei.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { LowerMinFeeUSD_Integration_Test } from "./../shared/lower-min-fee-usd/lowerMinFeeUSD.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleInstant_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleInstant} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleInstant;
        // Cast the {MerkleInstant} contract as {ISablierMerkleBase}
        merkleBase = merkleInstant;

        // Set the campaign type.
        campaignType = "instant";
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinFeeWei_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    CalculateMinFeeWei_Integration_Test
{
    function setUp() public override(MerkleInstant_Integration_Shared_Test, CalculateMinFeeWei_Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
        CalculateMinFeeWei_Integration_Test.setUp();
    }
}

contract Clawback_MerkleInstant_Integration_Test is MerkleInstant_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}

contract CollectFees_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    CollectFees_Integration_Test
{
    function setUp() public override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    HasClaimed_Integration_Test
{
    function setUp() public override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    HasExpired_Integration_Test
{
    function setUp() public override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();

        // Create a campaign with zero expiration to be used in this test.
        campaignWithZeroExpiration =
            ISablierMerkleBase(createMerkleInstant(merkleInstantConstructorParams({ expiration: 0 })));
    }
}

contract LowerMinFeeUSD_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    LowerMinFeeUSD_Integration_Test
{
    function setUp() public override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}
