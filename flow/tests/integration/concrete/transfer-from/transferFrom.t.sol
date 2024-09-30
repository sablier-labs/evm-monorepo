// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract TransferFrom_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        // Prank the recipient for this test.
        resetPrank({ msgSender: users.recipient });
    }

    function test_RevertGiven_StreamNotTransferable() external {
        // Create a non-transferrable stream.
        uint256 notTransferableStreamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: dai,
            transferable: false
        });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlowBase_NotTransferable.selector, notTransferableStreamId)
        );
        flow.transferFrom({ from: users.recipient, to: users.eve, tokenId: notTransferableStreamId });
    }

    function test_GivenStreamTransferable() external {
        // It should emit 1 {Transfer} and 1 {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(flow) });
        emit IERC721.Transfer({ from: users.recipient, to: users.sender, tokenId: defaultStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        flow.transferFrom({ from: users.recipient, to: users.sender, tokenId: defaultStreamId });

        // It should transfer the NFT.
        address actualRecipient = flow.getRecipient(defaultStreamId);
        address expectedRecipient = users.sender;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
