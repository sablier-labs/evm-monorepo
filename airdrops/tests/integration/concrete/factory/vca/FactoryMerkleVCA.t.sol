// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

import { SetNativeToken_Integration_Test } from "../shared/set-native-token/setNativeToken.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract FactoryMerkleVCA_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleVCA} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = ISablierFactoryMerkleBase(factoryMerkleVCA);

        // Assert that the comptroller is set correctly.
        assertEq(address(factoryMerkleBase.comptroller()), address(comptroller), "Comptroller mismatch");

        // Set the `merkleBase` to the merkleVCA contract to use it in the tests.
        merkleBase = ISablierMerkleBase(merkleVCA);

        // Set the campaign type.
        campaignType = "vca";

        // Claim to collect some fees.
        setMsgSender(users.recipient);
        claimTo();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract SetNativeToken_FactoryMerkleVCA_Integration_Test is
    FactoryMerkleVCA_Integration_Shared_Test,
    SetNativeToken_Integration_Test
{
    function setUp() public override(FactoryMerkleVCA_Integration_Shared_Test, Integration_Test) {
        FactoryMerkleVCA_Integration_Shared_Test.setUp();
    }
}
