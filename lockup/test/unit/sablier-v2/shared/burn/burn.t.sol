// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract Burn_Test is SharedTest {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        super.setUp();

        // Create the default stream, since most tests need it.
        defaultStreamId = createDefaultStream();

        // Make the recipient (owner of the NFT) the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamExistent() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamExistent.selector, defaultStreamId));
        sablierV2.burn(defaultStreamId);
    }

    modifier streamNonExistent() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_NFTNonExistent() external streamNonExistent {
        uint256 nonStreamId = 1729;
        vm.expectRevert("ERC721: invalid token ID");
        sablierV2.burn(nonStreamId);
    }

    modifier nftExistent() {
        // Cancel the stream so that the stream entity gets deleted.
        sablierV2.cancel(defaultStreamId);
        _;
    }

    /// @dev it should revert.
    function testFuzz_RevertWhen_CallerUnauthorized(address eve) external streamNonExistent nftExistent {
        vm.assume(eve != address(0) && eve != users.recipient);

        // Make Eve the caller in the rest of this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamId, eve));
        sablierV2.burn(defaultStreamId);
    }

    modifier callerAuthorized() {
        _;
    }

    /// @dev it should burn the NFT.
    function testFuzz_Burn_CallerApprovedOperator(
        address operator
    ) external streamNonExistent nftExistent callerAuthorized {
        vm.assume(operator != address(0) && operator != users.recipient);

        // Approve the operator to handle the stream.
        sablierV2.approve({ to: operator, tokenId: defaultStreamId });

        // Make the approved operator the caller in this test.
        changePrank(operator);

        // Burn the NFT.
        sablierV2.burn(defaultStreamId);

        // Assert that the NFT was burned.
        address actualOwner = sablierV2.getRecipient(defaultStreamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }

    /// @dev it should burn the NFT.
    function test_Burn_CallerNFTOwner() external streamNonExistent nftExistent callerAuthorized {
        sablierV2.burn(defaultStreamId);
        address actualOwner = sablierV2.getRecipient(defaultStreamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }
}
