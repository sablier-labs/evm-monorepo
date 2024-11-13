// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract GetRecipient_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, nullStreamId));
        lockup.getRecipient(nullStreamId);
    }

    function test_RevertGiven_BurnedNFT() external givenNotNull {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // Make the Recipient the caller.
        resetPrank({ msgSender: users.recipient });

        // Deplete the stream.
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        // Burn the NFT.
        lockup.burn(defaultStreamId);

        // Expect the relevant error when retrieving the recipient.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, defaultStreamId));
        lockup.getRecipient(defaultStreamId);
    }

    function test_GivenNotBurnedNFT() external view givenNotNull {
        address actualRecipient = lockup.getRecipient(defaultStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
