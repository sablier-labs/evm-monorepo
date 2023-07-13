// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract GetRecipient_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        defaultStreamId = createDefaultStream();
    }

    function test_RevertWhen_Null() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert("ERC721: invalid token ID");
        lockup.getRecipient(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    function test_RevertWhen_NFTBurned() external {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.END_TIME() });

        // Make the Recipient the caller.
        changePrank({ msgSender: users.recipient });

        // Deplete the stream.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Burn the NFT.
        lockup.burn(defaultStreamId);

        // Expect the relevant error when retrieving the recipient.
        vm.expectRevert("ERC721: invalid token ID");
        lockup.getRecipient(defaultStreamId);
    }

    modifier whenNFTNotBurned() {
        _;
    }

    function test_GetRecipient() external whenNotNull whenNFTNotBurned {
        address actualRecipient = lockup.getRecipient(defaultStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
