// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Create_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should create the stream.
    /// - It should bump the next stream ID.
    /// - It should mint the NFT.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {CreateFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for the sender and recipient.
    /// - Multiple values for the rate per second.
    /// - Multiple values for token decimals less than or equal to 18.
    /// - Both transferable and non-transferable streams.
    function testFuzz_Create(
        address recipient,
        address sender,
        UD21x18 ratePerSecond,
        uint8 decimals,
        bool transferable
    )
        external
        whenNoDelegateCall
    {
        // Check the sender and recipient are not zero.
        vm.assume(sender != address(0) && recipient != address(0));

        // Bound the variables.
        decimals = boundUint8(decimals, 0, 18);

        // Create a new token.
        token = createToken(decimals);

        uint256 expectedStreamId = flow.nextStreamId();

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(flow) });
        emit IERC721.Transfer({ from: address(0), to: recipient, tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.CreateFlowStream({
            streamId: expectedStreamId,
            sender: sender,
            recipient: recipient,
            ratePerSecond: ratePerSecond,
            token: token,
            transferable: transferable
        });

        // Create the stream.
        uint256 actualStreamId = flow.create({
            sender: sender,
            recipient: recipient,
            ratePerSecond: ratePerSecond,
            token: token,
            transferable: transferable
        });

        // Assert stream's initial states. This is the only place testing for state's getter functions.
        assertEq(flow.getBalance(actualStreamId), 0);
        assertEq(flow.getSnapshotTime(actualStreamId), getBlockTimestamp());
        assertEq(flow.getRatePerSecond(actualStreamId), ratePerSecond);
        assertEq(flow.getRecipient(actualStreamId), recipient);
        assertEq(flow.getSnapshotDebtScaled(actualStreamId), 0);
        assertEq(flow.getSender(actualStreamId), sender);
        assertEq(flow.getToken(actualStreamId), token);
        assertEq(flow.getTokenDecimals(actualStreamId), decimals);
        assertEq(flow.isStream(actualStreamId), true);
        assertEq(flow.isTransferable(actualStreamId), transferable);

        if (flow.getRatePerSecond(actualStreamId).unwrap() == 0) {
            assertEq(flow.isPaused(actualStreamId), true);
        } else {
            assertEq(flow.isPaused(actualStreamId), false);
        }

        // Assert that the next stream ID has been bumped.
        uint256 actualNextStreamId = flow.nextStreamId();
        uint256 expectedNextStreamId = expectedStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");

        // Assert that the minted NFT has the correct owner.
        address actualNFTOwner = flow.ownerOf({ tokenId: expectedStreamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
