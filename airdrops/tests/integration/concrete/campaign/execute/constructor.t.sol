// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { SablierMerkleExecute } from "src/SablierMerkleExecute.sol";
import { ClaimType } from "src/types/MerkleBase.sol";

import { MockStaking } from "../../../../mocks/MockStaking.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

contract Constructor_MerkleExecute_Integration_Concrete_Test is Integration_Test {
    function test_Constructor() external {
        // Make Factory the caller for the constructor test.
        setMsgSender(address(factoryMerkleExecute));

        // Deploy the SablierMerkleExecute contract.
        SablierMerkleExecute constructedExecute =
            new SablierMerkleExecute(merkleExecuteConstructorParams(), users.campaignCreator, address(comptroller));

        // SablierMerkleBase
        assertEq(constructedExecute.admin(), users.campaignCreator, "admin");
        assertEq(constructedExecute.campaignName(), CAMPAIGN_NAME, "campaign name");
        assertEq(constructedExecute.CAMPAIGN_START_TIME(), CAMPAIGN_START_TIME, "campaign start time");
        assertEq(uint8(constructedExecute.CLAIM_TYPE()), uint8(ClaimType.EXECUTE), "claim type");
        assertEq(constructedExecute.COMPTROLLER(), address(comptroller), "comptroller");
        assertEq(constructedExecute.EXPIRATION(), EXPIRATION, "expiration");
        assertEq(constructedExecute.ipfsCID(), IPFS_CID, "IPFS CID");
        assertEq(constructedExecute.IS_SABLIER_MERKLE(), true, "is sablier merkle");
        assertEq(constructedExecute.MERKLE_ROOT(), MERKLE_ROOT, "Merkle root");
        assertEq(constructedExecute.minFeeUSD(), AIRDROP_MIN_FEE_USD, "min fee USD");
        assertEq(address(constructedExecute.TOKEN()), address(dai), "token");

        // SablierMerkleExecute
        assertEq(constructedExecute.SELECTOR(), MockStaking.stake.selector, "selector");
        assertEq(constructedExecute.TARGET(), address(mockStaking), "target");
    }
}
