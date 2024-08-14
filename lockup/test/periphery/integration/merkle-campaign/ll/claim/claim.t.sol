// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup, LockupLinear } from "src/core/types/DataTypes.sol";

import { MerkleLL_Integration_Shared_Test } from "../MerkleLL.t.sol";
import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";

contract Claim_MerkleLL_Integration_Test is Claim_Integration_Test, MerkleLL_Integration_Shared_Test {
    function setUp() public override(Claim_Integration_Test, MerkleLL_Integration_Shared_Test) {
        super.setUp();
    }

    function test_ClaimLL() external givenCampaignNotExpired givenNotClaimed givenIncludedInMerkleTree {
        uint256 expectedStreamId = lockupLinear.nextStreamId();

        vm.expectEmit({ emitter: address(merkleLL) });
        emit Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);
        claim();

        LockupLinear.StreamLL memory actualStream = lockupLinear.getStream(expectedStreamId);
        LockupLinear.StreamLL memory expectedStream = LockupLinear.StreamLL({
            amounts: Lockup.Amounts({ deposited: defaults.CLAIM_AMOUNT(), refunded: 0, withdrawn: 0 }),
            asset: dai,
            cliffTime: getBlockTimestamp() + defaults.CLIFF_DURATION(),
            endTime: getBlockTimestamp() + defaults.TOTAL_DURATION(),
            isCancelable: defaults.CANCELABLE(),
            isDepleted: false,
            isStream: true,
            isTransferable: defaults.TRANSFERABLE(),
            recipient: users.recipient1,
            sender: users.admin,
            startTime: getBlockTimestamp(),
            wasCanceled: false
        });

        assertEq(actualStream, expectedStream);
        assertTrue(merkleLL.hasClaimed(defaults.INDEX1()), "not claimed");
    }
}
