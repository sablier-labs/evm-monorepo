// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Burn_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal streamId;
    uint256 internal notTransferableStreamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        streamId = createDefaultStream();
        notTransferableStreamId = createDefaultStreamNotTransferable();

        // Make the Recipient (owner of the NFT) the caller in this test suite.
        resetPrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierLockup.burn, streamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.burn(nullStreamId);
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenNotDepletedStream() {
        _;
    }

    function test_RevertGiven_PENDINGStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: getBlockTimestamp() - 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    function test_RevertGiven_STREAMINGStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    function test_RevertGiven_SETTLEDStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    function test_RevertGiven_CANCELEDStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        resetPrank({ msgSender: users.sender });
        lockup.cancel(streamId);
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    modifier givenDepletedStream(uint256 streamId_) {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: streamId_, to: users.recipient });
        _;
    }

    function test_RevertWhen_UnauthorizedCaller()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(streamId)
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Unauthorized.selector, streamId, users.eve));
        lockup.burn(streamId);
    }

    modifier whenAuthorizedCaller() {
        _;
    }

    function test_RevertGiven_NFTNotExist()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(streamId)
        whenAuthorizedCaller
    {
        // Burn the NFT so that it no longer exists.
        lockup.burn(streamId);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, streamId));
        lockup.burn(streamId);
    }

    modifier givenNFTExists() {
        _;
    }

    function test_GivenNonTransferableNFT()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(notTransferableStreamId)
        whenAuthorizedCaller
        givenNFTExists
    {
        // It should emit a {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: notTransferableStreamId });

        // Burn the NFT.
        lockup.burn(notTransferableStreamId);

        // It should burn the NFT.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, notTransferableStreamId));
        lockup.getRecipient(notTransferableStreamId);
    }

    modifier givenTransferableNFT() {
        _;
    }

    function test_WhenCallerApprovedThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(streamId)
        whenAuthorizedCaller
        givenNFTExists
        givenTransferableNFT
    {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: streamId });

        // Make the approved operator the caller in this test.
        resetPrank({ msgSender: users.operator });

        // It should emit a {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Burn the NFT.
        lockup.burn(streamId);

        // It should burn the NFT.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, streamId));
        lockup.getRecipient(streamId);
    }

    function test_WhenCallerNFTOwner()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(streamId)
        whenAuthorizedCaller
        givenNFTExists
        givenTransferableNFT
    {
        // It should emit a {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Burn the NFT.
        lockup.burn(streamId);

        // It should burn the NFT.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, streamId));
        lockup.getRecipient(streamId);
    }
}
