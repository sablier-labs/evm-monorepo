// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Broker, Lockup } from "src/types/DataTypes.sol";

import { BaseHandler } from "./BaseHandler.t.sol";

/// @title LockupHandler
/// @dev Common handler logic between {SablierV2LockupLinear} and {SablierV2LockupPro}.
abstract contract LockupHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_STREAM_COUNT = 100;

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Lockup public lockup;

    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address public admin;
    IERC20 public asset;
    uint256 public lastStreamId;
    uint128 public returnedAmountsSum;
    mapping(uint256 => address) public streamIdsToRecipients;
    mapping(uint256 => address) public streamIdsToSenders;
    uint256[] public streamIds;

    /*//////////////////////////////////////////////////////////////////////////
                              PRIVATE TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal currentRecipient;
    address internal currentSender;
    uint256 internal currentStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(address admin_, IERC20 asset_, ISablierV2Lockup linear_) {
        admin = admin_;
        asset = asset_;
        lockup = linear_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier useAdmin() {
        vm.startPrank(admin);
        _;
        vm.stopPrank();
    }

    modifier useFuzzedStreamRecipient(uint256 streamIndexSeed) {
        if (lastStreamId == 0) {
            return;
        }
        currentStreamId = streamIds[bound(streamIndexSeed, 0, lastStreamId - 1)];
        currentRecipient = streamIdsToRecipients[currentStreamId];
        vm.startPrank(currentRecipient);
        _;
        vm.stopPrank();
    }

    modifier useFuzzedStreamSender(uint256 streamIndexSeed) {
        if (lastStreamId == 0) {
            return;
        }
        currentStreamId = streamIds[bound(streamIndexSeed, 0, lastStreamId - 1)];
        currentSender = streamIdsToSenders[currentStreamId];
        vm.startPrank(currentSender);
        _;
        vm.stopPrank();
    }

    modifier useNewSender(address sender) {
        vm.startPrank(sender);
        _;
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function burn(uint256 streamIndexSeed) external instrument("burn") useFuzzedStreamRecipient(streamIndexSeed) {
        // Only canceled and depleted streams can be burned.
        Lockup.Status status = lockup.getStatus(currentStreamId);
        if (status != Lockup.Status.CANCELED && status != Lockup.Status.DEPLETED) {
            return;
        }

        // Only NFTs that still exist can be burned.
        if (currentRecipient == address(0)) {
            return;
        }

        // Burn the NFT.
        lockup.burn(currentStreamId);

        // Update the recipient associated with this stream id.
        streamIdsToRecipients[currentStreamId] = address(0);
    }

    function cancel(uint256 streamIndexSeed) external instrument("cancel") useFuzzedStreamSender(streamIndexSeed) {
        // Non-cancelable streams cannot be canceled.
        bool isCancelable = lockup.isCancelable(currentStreamId);
        if (!isCancelable) {
            return;
        }

        // Record the returned amount by adding it to the ghost variable `returnedAmountsSum`. This is needed to
        // check invariants against the contract's balance.
        uint128 returnedAmount = lockup.returnableAmountOf(currentStreamId);
        returnedAmountsSum += returnedAmount;

        // Cancel the stream.
        lockup.cancel(currentStreamId);
    }

    function claimProtocolRevenues() external instrument("claimProtocolRevenues") useAdmin {
        // Can claim revenues only if the protocol has revenues.
        uint128 protocolRevenues = lockup.getProtocolRevenues(asset);
        if (protocolRevenues == 0) {
            return;
        }

        // Claim the revenues.
        lockup.claimProtocolRevenues(asset);
    }

    function renounce(uint256 streamIndexSeed) external instrument("renounce") useFuzzedStreamSender(streamIndexSeed) {
        // Non-cancelable streams cannot be renounced.
        bool isCancelable = lockup.isCancelable(currentStreamId);
        if (!isCancelable) {
            return;
        }

        // Renounce the stream (make it non-cancelable).
        lockup.renounce(currentStreamId);
    }

    function withdraw(
        uint256 streamIndexSeed,
        address to,
        uint128 withdrawAmount
    ) external instrument("withdraw") useFuzzedStreamRecipient(streamIndexSeed) {
        // The protocol doesn't allow the `to` address to be the zero address.
        if (to == address(0)) {
            return;
        }

        // The protocol doesn't allow a zero amount to be withdrawn.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(currentStreamId);
        if (withdrawableAmount == 0) {
            return;
        }

        // Bound the withdraw amount so that it is not zero.
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Non-active streams cannot be withdrawn from.
        Lockup.Status status = lockup.getStatus(currentStreamId);
        if (status != Lockup.Status.ACTIVE) {
            return;
        }

        // Renounce the stream (make it non-cancelable).
        lockup.withdraw({ streamId: currentStreamId, to: to, amount: withdrawAmount });
    }

    function withdrawMax(
        uint256 streamIndexSeed,
        address to
    ) external instrument("withdrawMax") useFuzzedStreamRecipient(streamIndexSeed) {
        // The protocol doesn't allow the `to` address to be the zero address.
        if (to == address(0)) {
            return;
        }

        // The protocol doesn't allow a zero amount to be withdrawn.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(currentStreamId);
        if (withdrawableAmount == 0) {
            return;
        }

        // Non-active streams cannot be withdrawn from.
        Lockup.Status status = lockup.getStatus(currentStreamId);
        if (status != Lockup.Status.ACTIVE) {
            return;
        }

        // Renounce the stream (make it non-cancelable).
        lockup.withdrawMax({ streamId: currentStreamId, to: to });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      ERC-721
    //////////////////////////////////////////////////////////////////////////*/

    function transferNFT(
        uint256 streamIndexSeed,
        address newRecipient
    ) external instrument("transferNFT") useFuzzedStreamRecipient(streamIndexSeed) {
        // The ERC-721 contract doesn't allow the new recipient to be the zero address.
        if (newRecipient == address(0)) {
            return;
        }

        // Only NFTs that still exist can be transferred.
        if (currentRecipient == address(0)) {
            return;
        }

        // Transfer the NFT to the new recipient.
        lockup.transferFrom({ from: currentRecipient, to: newRecipient, tokenId: currentStreamId });

        // Update the recipient associated with this stream id.
        streamIdsToRecipients[currentStreamId] = newRecipient;
    }
}
