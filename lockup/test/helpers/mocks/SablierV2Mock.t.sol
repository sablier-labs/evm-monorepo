// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2 } from "src/SablierV2.sol";

contract SablierV2Mock is SablierV2 {
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee
    ) SablierV2(initialAdmin, initialComptroller, maxFee) {}

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

    function getDepositAmount(uint256 streamId) external pure override returns (uint128) {
        streamId;
        return 0;
    }

    function getERC20Token(uint256 streamId) external pure override returns (IERC20 token) {
        streamId;
        return IERC20(address(0));
    }

    function getRecipient(uint256 streamId) public pure override returns (address) {
        streamId;
        return address(0);
    }

    function getReturnableAmount(uint256 streamId) external pure override returns (uint128) {
        streamId;
        return 0;
    }

    function getSender(uint256 streamId) public pure override returns (address) {
        streamId;
        return address(0);
    }

    function getStartTime(uint256 streamId) external pure override returns (uint40) {
        streamId;
        return 0;
    }

    function getStopTime(uint256 streamId) external pure override returns (uint40) {
        streamId;
        return 0;
    }

    function getStreamedAmount(uint256 streamId) external pure override returns (uint128) {
        streamId;
        return 0;
    }

    function getWithdrawableAmount(uint256 streamId) public pure override returns (uint128) {
        streamId;
        return 0;
    }

    function getWithdrawnAmount(uint256 streamId) external pure override returns (uint128) {
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

    function isEntity(uint256 streamId) public pure override returns (bool) {
        streamId;
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

    function safeTransferFrom(address from, address to, uint256 tokenId) external pure {
        from;
        to;
        tokenId;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external pure {
        from;
        to;
        tokenId;
        data;
    }

    function setApprovalForAll(address operator, bool _approved) external pure {
        operator;
        _approved;
    }

    function transferFrom(address from, address to, uint256 tokenId) external pure {
        from;
        to;
        tokenId;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _burn(uint256 tokenId) internal pure override {
        tokenId;
    }

    function _cancel(uint256 streamId) internal pure override {
        streamId;
    }

    function _renounce(uint256 streamId) internal pure override {
        streamId;
    }

    function _withdraw(uint256 streamId, address to, uint128 amount) internal pure override {
        streamId;
        to;
        amount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _isApprovedOrOwner(uint256 streamId, address spender) internal pure override returns (bool) {
        streamId;
        spender;
        return true;
    }

    function _isCallerStreamSender(uint256 streamId) internal pure override returns (bool) {
        streamId;
        return true;
    }
}
