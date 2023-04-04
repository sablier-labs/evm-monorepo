// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetRecipient_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert("ERC721: invalid token ID");
        lockup.getRecipient(nullStreamId);
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_NFTBurned() external {
        changePrank({ msgSender: users.recipient });
        lockup.cancel(streamId);
        lockup.burn(streamId);
        vm.expectRevert("ERC721: invalid token ID");
        lockup.getRecipient(streamId);
    }

    modifier whenNFTNotBurned() {
        _;
    }

    /// @dev it should return the correct recipient.
    function test_GetRecipient() external whenStreamNonNull whenNFTNotBurned {
        address actualRecipient = lockup.getRecipient(streamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
