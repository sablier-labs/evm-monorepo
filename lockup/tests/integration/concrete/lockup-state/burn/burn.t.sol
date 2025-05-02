// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "../../../Integration.t.sol";

contract Burn_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_DelegateCall() external {
        expectRevert_DelegateCall({ callData: abi.encodeCall(lockup.burn, ids.defaultStream) });
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        expectRevert_Null({ callData: abi.encodeCall(lockup.burn, ids.nullStream) });
    }

    function test_RevertGiven_PENDINGStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        rewind(1 seconds);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, ids.defaultStream));
        lockup.burn(ids.defaultStream);
    }

    function test_RevertGiven_STREAMINGStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, ids.defaultStream));
        lockup.burn(ids.defaultStream);
    }

    function test_RevertGiven_SETTLEDStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, ids.defaultStream));
        lockup.burn(ids.defaultStream);
    }

    function test_RevertGiven_CANCELEDStatus() external whenNoDelegateCall givenNotNull givenNotDepletedStream {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        setMsgSender(users.sender);
        lockup.cancel(ids.defaultStream);
        setMsgSender(users.recipient);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamNotDepleted.selector, ids.defaultStream));
        lockup.burn(ids.defaultStream);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, ids.defaultStream)
        whenCallerNotRecipient
    {
        expectRevert_CallerMaliciousThirdParty({ callData: abi.encodeCall(lockup.burn, ids.defaultStream) });
    }

    function test_RevertWhen_CallerSender()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, ids.defaultStream)
        whenCallerNotRecipient
    {
        setMsgSender(users.sender);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_Unauthorized.selector, ids.defaultStream, users.sender)
        );
        lockup.burn(ids.defaultStream);
    }

    function test_WhenCallerApprovedThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, ids.defaultStream)
        whenCallerNotRecipient
    {
        // Make the third party the caller in this test.
        setMsgSender(users.operator);

        // It should burn the NFT.
        _test_Burn(ids.defaultStream);
    }

    function test_RevertGiven_NFTNotExist()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, ids.defaultStream)
        whenCallerRecipient
    {
        // Burn the NFT so that it no longer exists.
        lockup.burn(ids.defaultStream);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_Unauthorized.selector, ids.defaultStream, users.recipient)
        );
        lockup.burn(ids.defaultStream);
    }

    function test_GivenNonTransferableNFT()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, ids.notTransferableStream)
        whenCallerRecipient
        givenNFTExists
    {
        _test_Burn(ids.notTransferableStream);
    }

    function test_GivenTransferableNFT()
        external
        whenNoDelegateCall
        givenNotNull
        givenDepletedStream(lockup, ids.defaultStream)
        whenCallerRecipient
        givenNFTExists
    {
        _test_Burn(ids.defaultStream);
    }

    function _test_Burn(uint256 streamId) private {
        // It should emit a {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(lockup) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Burn the NFT.
        lockup.burn(streamId);

        // It should burn the NFT.
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, streamId));
        lockup.getRecipient(streamId);
    }
}
