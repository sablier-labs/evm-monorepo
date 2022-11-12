// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { SablierV2 } from "@sablier/v2-core/SablierV2.sol";

import { SablierV2BaseTest } from "../SablierV2BaseTest.t.sol";

contract AbstractSablierV2 is SablierV2 {
    constructor() SablierV2() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /*//////////////////////////////////////////////////////////////////////////
                              PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function balanceOf(address owner) external pure returns (uint256) {
        owner;
        return 0;
    }

    function getApproved(uint256 tokenId) external pure returns (address) {
        tokenId;
        return address(0);
    }

    function getDepositAmount(uint256 streamId) external pure override returns (uint256) {
        streamId;
        return 0;
    }

    function getRecipient(uint256 streamId) public pure override returns (address) {
        streamId;
        return address(0);
    }

    function getReturnableAmount(uint256 streamId) external pure override returns (uint256) {
        streamId;
        return 0;
    }

    function getSender(uint256 streamId) public pure override returns (address) {
        streamId;
        return address(0);
    }

    function getStartTime(uint256 streamId) external pure override returns (uint64) {
        streamId;
        return 0;
    }

    function getStopTime(uint256 streamId) external pure override returns (uint64) {
        streamId;
        return 0;
    }

    function getWithdrawableAmount(uint256 streamId) external pure override returns (uint256) {
        streamId;
        return 0;
    }

    function getWithdrawnAmount(uint256 streamId) external pure override returns (uint256) {
        streamId;
        return 0;
    }

    function isCancelable(uint256 streamId) public pure override returns (bool) {
        streamId;
        return true;
    }

    function isApprovedForAll(address owner, address operator) external pure returns (bool) {
        owner;
        operator;
        return true;
    }

    function ownerOf(uint256 tokenId) external pure returns (address) {
        tokenId;
        return address(0);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        interfaceId;
        return true;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function approve(address to, uint256 tokenId) external pure {
        to;
        tokenId;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external pure {
        from;
        to;
        tokenId;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external pure {
        from;
        to;
        tokenId;
        data;
    }

    function setApprovalForAll(address operator, bool _approved) external pure {
        operator;
        _approved;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external pure {
        from;
        to;
        tokenId;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _isApprovedOrOwner(address spender, uint256 streamId) internal pure override returns (bool) {
        spender;
        streamId;
        return true;
    }

    function _cancel(uint256 streamId) internal pure override {
        streamId;
    }

    function _renounce(uint256 streamId) internal pure override {
        streamId;
    }

    function _withdraw(
        uint256 streamId,
        address to,
        uint256 amount
    ) internal pure override {
        streamId;
        to;
        amount;
    }
}

/// @title AbstractSablierV2BaseTest
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract AbstractSablierV2BaseTest is SablierV2BaseTest {
    AbstractSablierV2 internal abstractSablierV2 = new AbstractSablierV2();

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }
}
