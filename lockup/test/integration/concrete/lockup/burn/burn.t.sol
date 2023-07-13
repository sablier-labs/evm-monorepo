// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Burn_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) {
        streamId = createDefaultStream();

        // Make the Recipient (owner of the NFT) the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.burn, streamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    function test_RevertWhen_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.burn(nullStreamId);
    }

    modifier whenNotNull() {
        _;
    }

    modifier whenStreamHasNotBeenDepleted() {
        _;
    }

    function test_RevertWhen_StreamHasNotBeenDepleted_StatusPending()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasNotBeenDepleted
    {
        vm.warp({ timestamp: getBlockTimestamp() - 1 seconds });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    function test_RevertWhen_StreamHasNotBeenDepleted_StatusStreaming()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasNotBeenDepleted
    {
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    function test_RevertWhen_StreamHasNotBeenDepleted_StatusSettled()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasNotBeenDepleted
    {
        vm.warp({ timestamp: defaults.END_TIME() });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    function test_RevertWhen_StreamHasNotBeenDepleted_StatusCanceled()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasNotBeenDepleted
    {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        lockup.cancel(streamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    modifier whenStreamHasBeenDepleted() {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });
        _;
    }

    function test_RevertWhen_CallerUnauthorized()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasBeenDepleted
    {
        // Make Eve the caller in the rest of this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, streamId, users.eve));
        lockup.burn(streamId);
    }

    modifier whenCallerAuthorized() {
        _;
    }

    function test_RevertWhen_NFTDoesNotExist()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasBeenDepleted
        whenCallerAuthorized
    {
        // Burn the NFT so that it no longer exists.
        lockup.burn(streamId);

        // Run the test.
        vm.expectRevert("ERC721: invalid token ID");
        lockup.burn(streamId);
    }

    modifier whenNFTExists() {
        _;
    }

    function test_Burn_CallerApprovedOperator()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasBeenDepleted
        whenCallerAuthorized
        whenNFTExists
    {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: streamId });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Burn the NFT.
        lockup.burn(streamId);

        // Assert that the NFT has been burned.
        vm.expectRevert("ERC721: invalid token ID");
        lockup.getRecipient(streamId);
    }

    function test_Burn_CallerNFTOwner()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamHasBeenDepleted
        whenCallerAuthorized
        whenNFTExists
    {
        lockup.burn(streamId);
        vm.expectRevert("ERC721: invalid token ID");
        lockup.getRecipient(streamId);
    }
}
