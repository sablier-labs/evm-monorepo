// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract TransferFrom_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();
        resetPrank({ msgSender: users.recipient });
    }

    function test_RevertGiven_StreamNotTransferable() external {
        uint256 notTransferableStreamId = openEnded.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai,
            isTransferable: false
        });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEndedState_NotTransferable.selector, notTransferableStreamId)
        );
        openEnded.transferFrom({ from: users.recipient, to: users.eve, tokenId: notTransferableStreamId });
    }

    modifier givenStreamTransferable() {
        _;
    }

    function test_TransferFrom() external givenStreamTransferable {
        // Create a stream.
        uint256 streamId = createDefaultStream();

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(openEnded) });
        emit Transfer({ from: users.recipient, to: users.sender, tokenId: streamId });
        vm.expectEmit({ emitter: address(openEnded) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Transfer the NFT.
        openEnded.transferFrom({ from: users.recipient, to: users.sender, tokenId: streamId });

        // Assert that Alice is the new stream recipient (and NFT owner).
        address actualRecipient = openEnded.getRecipient(streamId);
        address expectedRecipient = users.sender;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
