// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract Clawback_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotCampaignCreator() external {
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.campaignCreator, users.eve)
        );
        merkleBase.clawback({ to: users.eve, amount: 1 });
    }

    function test_WhenFirstClaimNotMade() external whenCallerCampaignCreator {
        _test_Clawback(users.campaignCreator);
    }

    modifier whenFirstClaimMade() {
        // Make the first claim to set `firstClaimTime`.
        setMsgSender(users.recipient);
        claimTo();

        // Change the caller back to the campaign creator.
        setMsgSender(users.campaignCreator);
        _;
    }

    function test_GivenSevenDaysNotPassed() external whenCallerCampaignCreator whenFirstClaimMade {
        // Skip forward by 6 days.
        skip(6 days);
        _test_Clawback(users.campaignCreator);
    }

    function test_RevertGiven_CampaignNotExpired()
        external
        whenCallerCampaignCreator
        whenFirstClaimMade
        givenSevenDaysPassed
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_ClawbackNotAllowed.selector, getBlockTimestamp(), EXPIRATION, FIRST_CLAIM_TIME
            )
        );
        merkleBase.clawback({ to: users.campaignCreator, amount: 1 });
    }

    function test_GivenCampaignExpired(address to)
        external
        whenCallerCampaignCreator
        whenFirstClaimMade
        givenSevenDaysPassed
    {
        vm.warp({ newTimestamp: EXPIRATION + 1 seconds });
        vm.assume(to != address(0));
        _test_Clawback(to);
    }

    function _test_Clawback(address to) private {
        uint128 clawbackAmount = uint128(dai.balanceOf(address(merkleBase)));
        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ to: to, value: clawbackAmount });
        // It should emit a {Clawback} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.Clawback({ admin: users.campaignCreator, to: to, amount: clawbackAmount });
        merkleBase.clawback({ to: to, amount: clawbackAmount });
    }
}
