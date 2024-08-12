// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as CoreErrors } from "src/core/libraries/Errors.sol";
import { Errors } from "src/periphery/libraries/Errors.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

contract Clawback_Integration_Test is MerkleCampaign_Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(CoreErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleLL.clawback({ to: users.eve, amount: 1 });
    }

    modifier whenCallerAdmin() {
        resetPrank({ msgSender: users.admin });
        _;
    }

    function test_Clawback_BeforeFirstClaim() external whenCallerAdmin {
        test_Clawback(users.admin);
    }

    modifier afterFirstClaim() {
        // Make the first claim to set `_firstClaimTime`.
        claimLL();
        _;
    }

    function test_Clawback_GracePeriod() external whenCallerAdmin afterFirstClaim {
        vm.warp({ newTimestamp: getBlockTimestamp() + 6 days });
        test_Clawback(users.admin);
    }

    modifier postGracePeriod() {
        vm.warp({ newTimestamp: getBlockTimestamp() + 8 days });
        _;
    }

    function test_RevertGiven_CampaignNotExpired() external whenCallerAdmin afterFirstClaim postGracePeriod {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_ClawbackNotAllowed.selector,
                getBlockTimestamp(),
                defaults.EXPIRATION(),
                defaults.FIRST_CLAIM_TIME()
            )
        );
        merkleLL.clawback({ to: users.admin, amount: 1 });
    }

    modifier givenCampaignExpired() {
        vm.warp({ newTimestamp: defaults.EXPIRATION() + 1 seconds });
        _;
    }

    function test_Clawback() external whenCallerAdmin afterFirstClaim postGracePeriod givenCampaignExpired {
        test_Clawback(users.admin);
    }

    function testFuzz_Clawback(address to)
        external
        whenCallerAdmin
        afterFirstClaim
        postGracePeriod
        givenCampaignExpired
    {
        vm.assume(to != address(0));
        test_Clawback(to);
    }

    function test_Clawback(address to) internal {
        uint128 clawbackAmount = uint128(dai.balanceOf(address(merkleLL)));
        expectCallToTransfer({ to: to, value: clawbackAmount });
        vm.expectEmit({ emitter: address(merkleLL) });
        emit Clawback({ admin: users.admin, to: to, amount: clawbackAmount });
        merkleLL.clawback({ to: to, amount: clawbackAmount });
    }
}
