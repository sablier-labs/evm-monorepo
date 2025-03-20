// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

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

abstract contract MerkleLT_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleLT} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleLT;
        // Cast the {MerkleLT} contract as {ISablierMerkleBase}
        merkleBase = merkleLT;

        // Set the campaign type.
        campaignType = "lt";
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CalculateMinFeeWei_MerkleLT_Integration_Test is
    MerkleLT_Integration_Shared_Test,
    CalculateMinFeeWei_Integration_Test
{
    function setUp() public override(MerkleLT_Integration_Shared_Test, CalculateMinFeeWei_Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
        CalculateMinFeeWei_Integration_Test.setUp();
    }
}

contract Clawback_MerkleLT_Integration_Test is MerkleLT_Integration_Shared_Test, Clawback_Integration_Test {
    function setUp() public override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
    }
}

contract CollectFees_MerkleLT_Integration_Test is MerkleLT_Integration_Shared_Test, CollectFees_Integration_Test {
    function setUp() public override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
    }
}

contract HasClaimed_MerkleLT_Integration_Test is MerkleLT_Integration_Shared_Test, HasClaimed_Integration_Test {
    function setUp() public override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
    }
}

contract HasExpired_MerkleLT_Integration_Test is MerkleLT_Integration_Shared_Test, HasExpired_Integration_Test {
    function setUp() public override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();

        // Create a campaign with zero expiry to be used in this test.
        campaignWithZeroExpiry = createMerkleLT(merkleLTConstructorParams({ expiration: 0 }));
    }
}

contract LowerMinFeeUSD_MerkleLT_Integration_Test is
    MerkleLT_Integration_Shared_Test,
    LowerMinFeeUSD_Integration_Test
{
    function setUp() public override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
    }
}
