// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleInstant } from "src/periphery/interfaces/ISablierMerkleInstant.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

contract HasExpired_Integration_Test is MerkleCampaign_Integration_Test {
    function test_HasExpired_ExpirationZero() external {
        ISablierMerkleInstant testLockup = createMerkleInstant({ expiration: 0 });
        assertFalse(testLockup.hasExpired(), "campaign expired");
    }

    modifier givenExpirationNotZero() {
        _;
    }

    function test_HasExpired_ExpirationLessThanBlockTimestamp() external view givenExpirationNotZero {
        assertFalse(merkleInstant.hasExpired(), "campaign expired");
    }

    function test_HasExpired_ExpirationEqualToBlockTimestamp() external givenExpirationNotZero {
        vm.warp({ newTimestamp: defaults.EXPIRATION() });
        assertTrue(merkleInstant.hasExpired(), "campaign not expired");
    }

    function test_HasExpired_ExpirationGreaterThanBlockTimestamp() external givenExpirationNotZero {
        vm.warp({ newTimestamp: defaults.EXPIRATION() + 1 seconds });
        assertTrue(merkleInstant.hasExpired(), "campaign not expired");
    }
}
