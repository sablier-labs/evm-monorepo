// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract GetRecipient_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        streamId = createDefaultStream();
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

        // Make the recipient the caller.
        changePrank({ msgSender: users.recipient });

        // Deplete the stream.
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });

        // Burn the NFT.
        lockup.burn(streamId);

        // Expect an error when accessing the recipient.
        vm.expectRevert("ERC721: invalid token ID");
        lockup.getRecipient(streamId);
    }

    modifier whenNFTNotBurned() {
        _;
    }

    function test_GetRecipient() external whenNotNull whenNFTNotBurned {
        address actualRecipient = lockup.getRecipient(streamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
