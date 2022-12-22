// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { Errors } from "src/libraries/Errors.sol";

import { ProTest } from "../ProTest.t.sol";

contract Burn__Test is ProTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the owner of the NFT the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotBurn__StreamExistent() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamExistent.selector, daiStreamId));
        pro.burn(daiStreamId);
    }

    modifier StreamNonExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotBurn__NFTNonExistent() external StreamNonExistent {
        uint256 nonStreamId = 1729;
        vm.expectRevert("ERC721: invalid token ID");
        pro.burn(nonStreamId);
    }

    modifier NFTExistent() {
        // Cancel the stream so that the stream entity gets deleted.
        pro.cancel(daiStreamId);
        _;
    }

    /// @dev it should revert.
    function testCannotBurn__CallerUnauthorized() external StreamNonExistent NFTExistent {
        // Make Eve the caller in the rest of this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        pro.burn(daiStreamId);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should burn the NFT.
    function testBurn__CallerApprovedOperator() external StreamNonExistent NFTExistent CallerAuthorized {
        // Approve the operator to handle the stream.
        pro.approve({ to: users.operator, tokenId: daiStreamId });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Run the test.
        pro.burn(daiStreamId);
        address actualOwner = pro.getRecipient(daiStreamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }

    /// @dev it should burn the NFT.
    function testBurn__CallerNFTOwner() external StreamNonExistent NFTExistent CallerAuthorized {
        pro.burn(daiStreamId);
        address actualOwner = pro.getRecipient(daiStreamId);
        address expectedOwner = address(0);
        assertEq(actualOwner, expectedOwner);
    }
}
