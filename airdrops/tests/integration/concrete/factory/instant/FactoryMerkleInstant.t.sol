// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

import { SetNativeToken_Integration_Test } from "../shared/set-native-token/setNativeToken.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract FactoryMerkleInstant_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleInstant} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = ISablierFactoryMerkleBase(factoryMerkleInstant);

        // Assert that the comptroller is set correctly.
        assertEq(address(factoryMerkleBase.comptroller()), address(comptroller), "Comptroller mismatch");

        // Set the `merkleBase` to the merkleInstant contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleInstant);

        // Set the campaign type.
        campaignType = "instant";

        // Claim to collect some fees.
        setMsgSender(users.recipient);
        claim();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract SetNativeToken_FactoryMerkleInstant_Integration_Test is
    FactoryMerkleInstant_Integration_Shared_Test,
    SetNativeToken_Integration_Test
{
    function setUp() public override(FactoryMerkleInstant_Integration_Shared_Test, Integration_Test) {
        FactoryMerkleInstant_Integration_Shared_Test.setUp();
    }
}
