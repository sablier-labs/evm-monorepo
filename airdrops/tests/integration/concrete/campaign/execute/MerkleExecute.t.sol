// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";

import { Integration_Test } from "./../../../Integration.t.sol";

import {
    CalculateMinFeeWei_Integration_Concrete_Test
} from "./../shared/calculate-min-fee-wei/calculateMinFeeWei.t.sol";
import { Clawback_Integration_Concrete_Test } from "./../shared/clawback/clawback.t.sol";
import { HasClaimed_Integration_Concrete_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Concrete_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { LowerMinFeeUSD_Integration_Concrete_Test } from "./../shared/lower-min-fee-usd/lowerMinFeeUSD.t.sol";
import { Sponsor_Integration_Concrete_Test } from "./../shared/sponsor/sponsor.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleExecute_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleExecute} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleExecute;

        // Cast the {MerkleExecute} contract as {ISablierMerkleBase}
        merkleBase = merkleExecute;

        // Set the campaign type.
        campaignType = "execute";
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinFeeWei_MerkleExecute_Integration_Concrete_Test is
    MerkleExecute_Integration_Shared_Test,
    CalculateMinFeeWei_Integration_Concrete_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract Clawback_MerkleExecute_Integration_Concrete_Test is
    MerkleExecute_Integration_Shared_Test,
    Clawback_Integration_Concrete_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleExecute_Integration_Concrete_Test is
    MerkleExecute_Integration_Shared_Test,
    HasClaimed_Integration_Concrete_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleExecute_Integration_Concrete_Test is
    MerkleExecute_Integration_Shared_Test,
    HasExpired_Integration_Concrete_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();

        // Create a campaign with zero expiration to be used in this test.
        campaignWithZeroExpiration =
            ISablierMerkleBase(createMerkleExecute(merkleExecuteConstructorParams({ expiration: 0 })));
    }
}

contract LowerMinFeeUSD_MerkleExecute_Integration_Concrete_Test is
    MerkleExecute_Integration_Shared_Test,
    LowerMinFeeUSD_Integration_Concrete_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}

contract Sponsor_MerkleExecute_Integration_Concrete_Test is
    MerkleExecute_Integration_Shared_Test,
    Sponsor_Integration_Concrete_Test
{
    function setUp() public override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();
    }
}
