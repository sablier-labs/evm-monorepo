// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Shared_Test } from "../SharedTest.t.sol";

abstract contract Burn_Test is Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient (owner of the NFT) the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCanceledOrDepleted.selector, nullStreamId)
        );
        lockup.burn(nullStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamActive() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotCanceledOrDepleted.selector, streamId));
        lockup.burn(streamId);
    }

    /// @dev This modifier runs the test twice, once with a canceled stream, and once with a depleted stream.
    modifier streamCanceledOrDepleted() {
        lockup.cancel(streamId);
        _;
        changePrank(users.recipient);
        streamId = createDefaultStream();
        vm.warp({ timestamp: DEFAULT_STOP_TIME });
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorized(address eve) external streamCanceledOrDepleted {
        vm.assume(eve != address(0) && eve != users.recipient);

        // Make Eve the caller in the rest of this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, streamId, eve));
        lockup.burn(streamId);
    }

    modifier callerAuthorized() {
        _;
    }

    /// @dev it should burn the NFT.
    function testFuzz_Burn_CallerApprovedOperator(address operator) external streamCanceledOrDepleted callerAuthorized {
        vm.assume(operator != address(0) && operator != users.recipient);

        // Approve the operator to handle the stream.
        lockup.approve({ to: operator, tokenId: streamId });

        // Make the approved operator the caller in this test.
        changePrank(operator);

        // Burn the NFT.
        lockup.burn(streamId);

        // Assert that the NFT was burned.
        address actualNFTOwner = lockup.getRecipient(streamId);
        address expectedNFTOwner = address(0);
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    /// @dev it should burn the NFT.
    function test_Burn_CallerNFTOwner() external streamCanceledOrDepleted callerAuthorized {
        lockup.burn(streamId);
        address actualNFTOwner = lockup.getRecipient(streamId);
        address expectedNFTOwner = address(0);
        assertEq(actualNFTOwner, expectedNFTOwner);
    }
}
