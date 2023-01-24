// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract Burn_Test is SharedTest {
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
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamNotCanceledOrDepleted.selector, nullStreamId));
        sablierV2.burn(nullStreamId);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamActive() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamNotCanceledOrDepleted.selector, streamId));
        sablierV2.burn(streamId);
    }

    /// @dev This modifier runs the test twice, once with a canceled stream, and once with a depleted stream.
    modifier streamCanceledOrDepleted() {
        sablierV2.cancel(streamId);
        _;
        changePrank(users.recipient);
        streamId = createDefaultStream();
        vm.warp({ timestamp: DEFAULT_STOP_TIME });
        sablierV2.withdrawMax({ streamId: streamId, to: users.recipient });
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorized(address eve) external streamCanceledOrDepleted {
        vm.assume(eve != address(0) && eve != users.recipient);

        // Make Eve the caller in the rest of this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, streamId, eve));
        sablierV2.burn(streamId);
    }

    modifier callerAuthorized() {
        _;
    }

    /// @dev it should burn the NFT.
    function testFuzz_Burn_CallerApprovedOperator(address operator) external streamCanceledOrDepleted callerAuthorized {
        vm.assume(operator != address(0) && operator != users.recipient);

        // Approve the operator to handle the stream.
        sablierV2.approve({ to: operator, tokenId: streamId });

        // Make the approved operator the caller in this test.
        changePrank(operator);

        // Burn the NFT.
        sablierV2.burn(streamId);

        // Assert that the NFT was burned.
        address actualOwner = sablierV2.getRecipient(streamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }

    /// @dev it should burn the NFT.
    function test_Burn_CallerNFTOwner() external streamCanceledOrDepleted callerAuthorized {
        sablierV2.burn(streamId);
        address actualOwner = sablierV2.getRecipient(streamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }
}
