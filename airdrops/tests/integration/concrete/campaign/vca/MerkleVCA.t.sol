// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "../../../Integration.t.sol";
import { CalculateMinFeeWei_Integration_Test } from "./../shared/calculate-min-fee-wei/calculateMinFeeWei.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { LowerMinFeeUSD_Integration_Test } from "./../shared/lower-min-fee-usd/lowerMinFeeUSD.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleVCA_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleVCA} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleVCA;
        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}
        merkleBase = merkleVCA;

        // Set the campaign type.
        campaignType = "vca";
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinFeeWei_MerkleVCA_Integration_Test is
    MerkleVCA_Integration_Shared_Test,
    CalculateMinFeeWei_Integration_Test
{
    function setUp() public override(MerkleVCA_Integration_Shared_Test, CalculateMinFeeWei_Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
        CalculateMinFeeWei_Integration_Test.setUp();
    }
}

contract Clawback_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract CollectFees_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, CollectFees_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, HasClaimed_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleVCA_Integration_Test is MerkleVCA_Integration_Shared_Test, HasExpired_Integration_Test {
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}

contract LowerMinFeeUSD_MerkleVCA_Integration_Test is
    MerkleVCA_Integration_Shared_Test,
    LowerMinFeeUSD_Integration_Test
{
    function setUp() public override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }
}
