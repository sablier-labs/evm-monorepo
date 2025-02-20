// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract Clawback_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotCampaignOwner() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.campaignOwner, users.eve));
        merkleBase.clawback({ to: users.eve, amount: 1 });
    }

    function test_WhenFirstClaimNotMade() external whenCallerCampaignOwner {
        test_Clawback(users.campaignOwner);
    }

    modifier whenFirstClaimMade() {
        // Make the first claim to set `_firstClaimTime`.
        claim();

        // Reset the prank back to the campaign owner.
        resetPrank(users.campaignOwner);
        _;
    }

    function test_GivenSevenDaysNotPassed() external whenCallerCampaignOwner whenFirstClaimMade {
        vm.warp({ newTimestamp: getBlockTimestamp() + 6 days });
        test_Clawback(users.campaignOwner);
    }

    function test_RevertGiven_CampaignNotExpired()
        external
        whenCallerCampaignOwner
        whenFirstClaimMade
        givenSevenDaysPassed
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_ClawbackNotAllowed.selector,
                getBlockTimestamp(),
                defaults.EXPIRATION(),
                defaults.FIRST_CLAIM_TIME()
            )
        );
        merkleBase.clawback({ to: users.campaignOwner, amount: 1 });
    }

    function test_GivenCampaignExpired(address to)
        external
        whenCallerCampaignOwner
        whenFirstClaimMade
        givenSevenDaysPassed
    {
        vm.warp({ newTimestamp: defaults.EXPIRATION() + 1 seconds });
        vm.assume(to != address(0));
        test_Clawback(to);
    }

    function test_Clawback(address to) internal {
        uint128 clawbackAmount = uint128(dai.balanceOf(address(merkleBase)));
        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ to: to, value: clawbackAmount });
        // It should emit a {Clawback} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.Clawback({ admin: users.campaignOwner, to: to, amount: clawbackAmount });
        merkleBase.clawback({ to: to, amount: clawbackAmount });
    }
}
