// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract Burn_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient (owner of the NFT) the caller in this test suite.
        changePrank({ msgSender: users.recipient });
    }

    /// @dev it should revert.
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2Lockup.burn, streamId);
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCanceledOrDepleted.selector, nullStreamId)
        );
        lockup.burn(nullStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamActive() external whenNoDelegateCall {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCanceledOrDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    /// @dev This modifier runs the test twice, once with a canceled stream, and once with a depleted stream.
    modifier whenStreamCanceledOrDepleted() {
        lockup.cancel(streamId);
        _;
        changePrank({ msgSender: users.recipient });
        streamId = createDefaultStream();
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized() external whenNoDelegateCall whenStreamCanceledOrDepleted {
        // Make Eve the caller in the rest of this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, streamId, users.eve));
        lockup.burn(streamId);
    }

    modifier whenCallerAuthorized() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_NFTNonExistent()
        external
        whenNoDelegateCall
        whenStreamCanceledOrDepleted
        whenCallerAuthorized
    {
        // Burn the NFT so that it no longer exists.
        lockup.burn(streamId);

        // Run the test.
        vm.expectRevert("ERC721: invalid token ID");
        lockup.burn(streamId);
    }

    modifier whenNFTExistent() {
        _;
    }

    /// @dev it should burn the NFT.
    function test_Burn_CallerApprovedOperator()
        external
        whenNoDelegateCall
        whenStreamCanceledOrDepleted
        whenCallerAuthorized
        whenNFTExistent
    {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: streamId });

        // Make the approved operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Burn the NFT.
        lockup.burn(streamId);

        // Assert that the NFT has been burned.
        address actualNFTOwner = lockup.getRecipient(streamId);
        address expectedNFTOwner = address(0);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    /// @dev it should burn the NFT.
    function test_Burn_CallerNFTOwner()
        external
        whenNoDelegateCall
        whenStreamCanceledOrDepleted
        whenCallerAuthorized
        whenNFTExistent
    {
        lockup.burn(streamId);
        address actualNFTOwner = lockup.getRecipient(streamId);
        address expectedNFTOwner = address(0);
        assertEq(actualNFTOwner, expectedNFTOwner);
    }
}
