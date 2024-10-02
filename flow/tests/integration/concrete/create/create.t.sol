// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ud21x18 } from "@prb/math/src/UD21x18.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Flow } from "src/types/DataTypes.sol";
import { ERC20Mock } from "./../../../mocks/ERC20Mock.sol";
import { Integration_Test } from "./../../Integration.t.sol";

contract Create_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(flow.create, (users.sender, users.recipient, RATE_PER_SECOND, dai, TRANSFERABLE));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertWhen_SenderAddressZero() external whenNoDelegateCall {
        vm.expectRevert(Errors.SablierFlow_SenderZeroAddress.selector);
        flow.create({
            sender: address(0),
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: dai,
            transferable: TRANSFERABLE
        });
    }

    function test_RevertWhen_TokenNotImplementDecimals() external whenNoDelegateCall whenSenderNotAddressZero {
        address invalidToken = address(8128);
        vm.expectRevert(bytes(""));
        flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: IERC20(invalidToken),
            transferable: TRANSFERABLE
        });
    }

    function test_RevertWhen_TokenDecimalsExceeds18()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenTokenImplementsDecimals
    {
        IERC20 tokenWith24Decimals = new ERC20Mock("Token With More Decimals", "TWMD", 24);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlow_InvalidTokenDecimals.selector, address(tokenWith24Decimals))
        );

        flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: tokenWith24Decimals,
            transferable: TRANSFERABLE
        });
    }

    function test_RevertWhen_RecipientAddressZero()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenTokenImplementsDecimals
        whenTokenDecimalsNotExceed18
    {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidReceiver.selector, address(0)));
        flow.create({
            sender: users.sender,
            recipient: address(0),
            ratePerSecond: RATE_PER_SECOND,
            token: dai,
            transferable: TRANSFERABLE
        });
    }

    function test_WhenRatePerSecondZero()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenTokenImplementsDecimals
        whenTokenDecimalsNotExceed18
        whenRecipientNotAddressZero
    {
        // it should create a paused stream

        uint256 streamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: ud21x18(0),
            token: dai,
            transferable: TRANSFERABLE
        });

        assertTrue(flow.isStream(streamId));
        assertEq(uint8(flow.statusOf(streamId)), uint8(Flow.Status.PAUSED_SOLVENT));
    }

    function test_WhenRatePerSecondNotZero()
        external
        whenNoDelegateCall
        whenSenderNotAddressZero
        whenTokenImplementsDecimals
        whenTokenDecimalsNotExceed18
    {
        uint256 expectedStreamId = flow.nextStreamId();

        // It should emit 1 {MetadataUpdate}, 1 {CreateFlowStream} and 1 {Transfer} events.
        vm.expectEmit({ emitter: address(flow) });
        emit IERC721.Transfer({ from: address(0), to: users.recipient, tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.CreateFlowStream({
            streamId: expectedStreamId,
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: usdc,
            transferable: TRANSFERABLE
        });

        // Create the stream.
        uint256 actualStreamId = flow.create({
            sender: users.sender,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            token: usdc,
            transferable: TRANSFERABLE
        });

        Flow.Stream memory actualStream = flow.getStream(actualStreamId);
        Flow.Stream memory expectedStream = defaultStream();

        // It should create the `STREAMING` stream.
        assertEq(actualStreamId, expectedStreamId, "stream id");
        assertEq(actualStream, expectedStream);
        assertEq(uint8(flow.statusOf(actualStreamId)), uint8(Flow.Status.STREAMING_SOLVENT));

        // It should bump the next stream id.
        assertEq(flow.nextStreamId(), expectedStreamId + 1, "next stream id");

        // It should mint the NFT.
        address actualNFTOwner = flow.ownerOf({ tokenId: actualStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }
}
