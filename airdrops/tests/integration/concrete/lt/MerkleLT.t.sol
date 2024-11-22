// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Integration_Test } from "../../Integration.t.sol";
import { Clawback_Integration_Test } from "./../shared/clawback/clawback.t.sol";
import { CollectFees_Integration_Test } from "./../shared/collect-fees/collectFees.t.sol";
import { GetFirstClaimTime_Integration_Test } from "./../shared/get-first-claim-time/getFirstClaimTime.t.sol";
import { HasClaimed_Integration_Test } from "./../shared/has-claimed/hasClaimed.t.sol";
import { HasExpired_Integration_Test } from "./../shared/has-expired/hasExpired.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                             NON-SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

abstract contract MerkleLT_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {MerkleLT} contract as {ISablierMerkleBase}
        merkleBase = ISablierMerkleBase(merkleLT);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

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

contract GetFirstClaimTime_MerkleLT_Integration_Test is
    MerkleLT_Integration_Shared_Test,
    GetFirstClaimTime_Integration_Test
{
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
    }
}
