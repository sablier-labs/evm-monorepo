// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "./../../../Integration.t.sol";
import { CalculateMinFeeWei_Integration_Test } from "./../shared/calculate-min-fee-wei/calculateMinFeeWei.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { LowerMinFeeUSD_Integration_Test } from "./../shared/lower-min-fee-usd/lowerMinFeeUSD.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleLL_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleLL} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleLL;
        // Cast the {MerkleLL} contract as {ISablierMerkleBase}
        merkleBase = merkleLL;

        // Set the campaign type.
        campaignType = "ll";
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinFeeWei_MerkleLL_Integration_Test is
    MerkleLL_Integration_Shared_Test,
    CalculateMinFeeWei_Integration_Test
{
    function setUp() public override(MerkleLL_Integration_Shared_Test, CalculateMinFeeWei_Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
        CalculateMinFeeWei_Integration_Test.setUp();
    }
}

contract Clawback_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, HasClaimed_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleLL_Integration_Test is MerkleLL_Integration_Shared_Test, HasExpired_Integration_Test {
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();

        // Create a campaign with zero expiration.
        campaignWithZeroExpiration = createMerkleLL(merkleLLConstructorParams({ expiration: 0 }));
    }
}

contract LowerMinFeeUSD_MerkleLL_Integration_Test is
    MerkleLL_Integration_Shared_Test,
    LowerMinFeeUSD_Integration_Test
{
    function setUp() public override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }
}
