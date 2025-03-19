// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract HasExpired_Integration_Test is Integration_Test {
    /// @notice A campaign, without expiry, should be set in the child contract inheriting it.
    /// @dev Since VCA campaign does not allow 0 expiry, this applies to non-VCA campaigns only.
    ISablierMerkleBase internal campaignWithZeroExpiry;

    function test_GivenCampaignIsNotVca() external view whenExpirationZero {
        // Assert only for non-VCA campaigns.
        if (!Strings.equal(campaignType, "vca")) {
            assertFalse(campaignWithZeroExpiry.hasExpired(), "campaign expired");
        }
    }

    function test_WhenExpirationInPast() external view whenExpirationNotZero {
        assertFalse(merkleBase.hasExpired(), "campaign expired");
    }

    function test_WhenTheExpirationInPresent() external whenExpirationNotZero {
        vm.warp({ newTimestamp: EXPIRATION });
        assertTrue(merkleBase.hasExpired(), "campaign not expired");
    }

    function test_WhenTheExpirationInFuture() external whenExpirationNotZero {
        vm.warp({ newTimestamp: EXPIRATION + 1 seconds });
        assertTrue(merkleBase.hasExpired(), "campaign not expired");
    }
}
