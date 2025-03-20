// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { GetFee_Integration_Test } from "./../shared/get-fee/getFee.t.sol";
import { ResetCustomFee_Integration_Test } from "./../shared/reset-custom-fee/resetCustomFee.t.sol";
import { SetCustomFee_Integration_Test } from "./../shared/set-custom-fee/setCustomFee.t.sol";
import { SetMinimumFee_Integration_Test } from "./../shared/set-minimum-fee/setMinimumFee.t.sol";
import { SetNativeToken_Integration_Test } from "./../shared/set-native-token/setNativeToken.t.sol";
import { SetOracle_Integration_Test } from "./../shared/set-oracle/setOracle.t.sol";
/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleFactoryInstant_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryInstant} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = ISablierMerkleFactoryBase(merkleFactoryInstant);

        // Set the `merkleBase` to the merkleInstant contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleInstant);

        // Claim to collect some fees.
        resetPrank(users.recipient);
        claim();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract CollectFees_MerkleFactoryInstant_Integration_Test is
    MerkleFactoryInstant_Integration_Shared_Test,
    CollectFees_Integration_Test
{
    function setUp() public override(MerkleFactoryInstant_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryInstant_Integration_Shared_Test.setUp();
    }
}

contract GetFee_MerkleFactoryInstant_Integration_Test is
    MerkleFactoryInstant_Integration_Shared_Test,
    GetFee_Integration_Test
{
    function setUp() public override(MerkleFactoryInstant_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryInstant_Integration_Shared_Test.setUp();
    }
}

contract ResetCustomFee_MerkleFactoryInstant_Integration_Test is
    MerkleFactoryInstant_Integration_Shared_Test,
    ResetCustomFee_Integration_Test
{
    function setUp() public override(MerkleFactoryInstant_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryInstant_Integration_Shared_Test.setUp();
    }
}

contract SetCustomFee_MerkleFactoryInstant_Integration_Test is
    MerkleFactoryInstant_Integration_Shared_Test,
    SetCustomFee_Integration_Test
{
    function setUp() public override(MerkleFactoryInstant_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryInstant_Integration_Shared_Test.setUp();
    }
}

contract SetMinimumFee_MerkleFactoryInstant_Integration_Test is
    MerkleFactoryInstant_Integration_Shared_Test,
    SetMinimumFee_Integration_Test
{
    function setUp() public override(MerkleFactoryInstant_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryInstant_Integration_Shared_Test.setUp();
    }
}

contract SetNativeToken_MerkleFactoryInstant_Integration_Test is
    MerkleFactoryInstant_Integration_Shared_Test,
    SetNativeToken_Integration_Test
{
    function setUp() public override(MerkleFactoryInstant_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryInstant_Integration_Shared_Test.setUp();
    }
}

contract SetOracle_MerkleFactoryInstant_Integration_Test is
    MerkleFactoryInstant_Integration_Shared_Test,
    SetOracle_Integration_Test
{
    function setUp() public override(MerkleFactoryInstant_Integration_Shared_Test, Integration_Test) {
        MerkleFactoryInstant_Integration_Shared_Test.setUp();
    }
}
