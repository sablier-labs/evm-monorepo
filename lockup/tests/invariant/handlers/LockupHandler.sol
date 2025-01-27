// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { LockupStore } from "../stores/LockupStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

contract LockupHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupStore public lockupStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal currentRecipient;
    address internal currentSender;
    uint256 internal currentStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 token_, LockupStore lockupStore_, ISablierLockup lockup_) BaseHandler(token_, lockup_) {
        lockupStore = lockupStore_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Picks a random stream from the store.
    /// @param streamIndexSeed A fuzzed value needed for picking the random stream.
    modifier useFuzzedStream(uint256 streamIndexSeed) {
        uint256 lastStreamId = lockupStore.lastStreamId();
        vm.assume(lastStreamId != 0);
        uint256 fuzzedStreamId = _bound(streamIndexSeed, 0, lastStreamId - 1);
        currentStreamId = lockupStore.streamIds(fuzzedStreamId);
        _;
    }

    modifier useFuzzedStreamRecipient() {
        currentRecipient = lockupStore.recipients(currentStreamId);
        resetPrank(currentRecipient);
        vm.deal({ account: currentRecipient, newBalance: 100 ether });
        _;
    }

    modifier useFuzzedStreamSender() {
        currentSender = lockupStore.senders(currentStreamId);
        resetPrank(currentSender);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function burn(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed
    )
        external
        instrument("burn")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
    {
        // Only depleted streams can be burned.
        vm.assume(lockup.statusOf(currentStreamId) == Lockup.Status.DEPLETED);

        // Only NFTs that still exist can be burned.
        vm.assume(currentRecipient != address(0));

        // Burn the NFT.
        lockup.burn(currentStreamId);

        // Set the recipient associated with this stream to the zero address.
        lockupStore.updateRecipient(currentStreamId, address(0));
    }

    function cancel(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed
    )
        external
        instrument("cancel")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // Cold streams cannot be withdrawn from.
        vm.assume(!lockup.isCold(currentStreamId));

        // Not cancelable streams cannot be canceled.
        vm.assume(lockup.isCancelable(currentStreamId));

        // Cancel the stream.
        lockup.cancel(currentStreamId);
    }

    function renounce(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed
    )
        external
        instrument("renounce")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamSender
    {
        // Cold streams cannot be renounced.
        vm.assume(!lockup.isCold(currentStreamId));

        // Not cancelable streams cannot be renounced.
        vm.assume(lockup.isCancelable(currentStreamId));

        // Renounce the stream (make it not cancelable).
        lockup.renounce(currentStreamId);
    }

    function withdraw(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        address to,
        uint128 withdrawAmount,
        bool payFee
    )
        external
        instrument("withdraw")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
    {
        // Pending and depleted streams cannot be withdrawn from.
        Lockup.Status status = lockup.statusOf(currentStreamId);
        vm.assume(status != Lockup.Status.PENDING && status != Lockup.Status.DEPLETED);

        // The protocol doesn't allow the withdrawal address to be the zero address.
        vm.assume(to != address(0));

        // The protocol doesn't allow zero withdrawal amounts.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(currentStreamId);
        vm.assume(withdrawableAmount != 0);

        // Bound the withdraw amount so that it is not zero.
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // There is an edge case when the sender is the same as the recipient. In this scenario, the withdrawal
        // address must be set to the recipient.
        address sender = lockupStore.senders(currentStreamId);
        if (sender == currentRecipient && to != currentRecipient) {
            to = currentRecipient;
        }

        // Withdraw from the stream.
        lockup.withdraw{ value: payFee ? FEE : 0 }({ streamId: currentStreamId, to: to, amount: withdrawAmount });
    }

    function collectFees() external instrument("collectFees") {
        lockup.collectFees();
    }

    function withdrawMax(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        address to,
        bool payFee
    )
        external
        instrument("withdrawMax")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
    {
        // Pending and depleted streams cannot be withdrawn from.
        Lockup.Status status = lockup.statusOf(currentStreamId);
        vm.assume(status != Lockup.Status.PENDING && status != Lockup.Status.DEPLETED);

        // The protocol doesn't allow the withdrawal address to be the zero address.
        vm.assume(to != address(0));

        // The protocol doesn't allow a zero amount to be withdrawn.
        vm.assume(lockup.withdrawableAmountOf(currentStreamId) != 0);

        // There is an edge case when the sender is the same as the recipient. In this scenario, the withdrawal
        // address must be set to the recipient.
        address sender = lockupStore.senders(currentStreamId);
        if (sender == currentRecipient && to != currentRecipient) {
            to = currentRecipient;
        }

        // Make the max withdrawal.
        lockup.withdrawMax{ value: payFee ? FEE : 0 }({ streamId: currentStreamId, to: to });
    }

    function withdrawMaxAndTransfer(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        address newRecipient,
        bool payFee
    )
        external
        instrument("withdrawMaxAndTransfer")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
    {
        // Pending and depleted streams cannot be withdrawn from.
        Lockup.Status status = lockup.statusOf(currentStreamId);
        vm.assume(status != Lockup.Status.PENDING && status != Lockup.Status.DEPLETED);

        // OpenZeppelin's ERC-721 implementation doesn't allow the new recipient to be the zero address.
        vm.assume(newRecipient != address(0));

        // Skip burned NFTs.
        vm.assume(currentRecipient != address(0));

        // Skip if the stream is not transferable.
        vm.assume(lockup.isTransferable(currentStreamId));

        // The protocol doesn't allow a zero amount to be withdrawn.
        vm.assume(lockup.withdrawableAmountOf(currentStreamId) != 0);

        // Make the max withdrawal and transfer the NFT.
        lockup.withdrawMaxAndTransfer{ value: payFee ? FEE : 0 }({
            streamId: currentStreamId,
            newRecipient: newRecipient
        });

        // Update the recipient associated with this stream ID.
        lockupStore.updateRecipient(currentStreamId, newRecipient);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      ERC-721
    //////////////////////////////////////////////////////////////////////////*/

    function transferNFT(
        uint256 timeJumpSeed,
        uint256 streamIndexSeed,
        address newRecipient
    )
        external
        instrument("transferNFT")
        adjustTimestamp(timeJumpSeed)
        useFuzzedStream(streamIndexSeed)
        useFuzzedStreamRecipient
    {
        // OpenZeppelin's ERC-721 implementation doesn't allow the new recipient to be the zero address.
        vm.assume(newRecipient != address(0));

        // Skip burned NFTs.
        vm.assume(currentRecipient != address(0));

        // Skip if the stream is not transferable.
        vm.assume(lockup.isTransferable(currentStreamId));

        // Transfer the NFT to the new recipient.
        lockup.transferFrom({ from: currentRecipient, to: newRecipient, tokenId: currentStreamId });

        // Update the recipient associated with this stream ID.
        lockupStore.updateRecipient(currentStreamId, newRecipient);
    }
}
