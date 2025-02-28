// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { GetFirstClaimTime_Integration_Test } from "./../shared/get-first-claim-time/getFirstClaimTime.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";
import { LowerMinimumFee_Integration_Test } from "./../shared/lower-minimum-fee/lowerMinimumFee.t.sol";
import { MinimumFeeInWei_Integration_Test } from "./../shared/minimum-fee-in-wei/minimumFeeInWei.t.sol";
/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleInstant_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryInstant} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryInstant);

        // Cast the {merkleInstant} contract as {ISablierMerkleBase}
        merkleBase = ISablierMerkleBase(merkleInstant);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

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

contract GetFirstClaimTime_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    GetFirstClaimTime_Integration_Test
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
    }
}

contract LowerMinimumFee_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    LowerMinimumFee_Integration_Test
{
    function setUp() public override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}

contract MinimumFeeInWei_MerkleInstant_Integration_Test is
    MerkleInstant_Integration_Shared_Test,
    MinimumFeeInWei_Integration_Test("instant")
{
    function setUp() public override(MerkleInstant_Integration_Shared_Test, Integration_Test) {
        MerkleInstant_Integration_Shared_Test.setUp();
    }
}
