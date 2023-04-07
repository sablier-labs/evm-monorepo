// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/token/ERC721/ERC721.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { SablierV2Lockup } from "./abstracts/SablierV2Lockup.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "./interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupLinear } from "./interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2NFTDescriptor } from "./interfaces/ISablierV2NFTDescriptor.sol";
import { ISablierV2LockupRecipient } from "./interfaces/hooks/ISablierV2LockupRecipient.sol";
import { ISablierV2LockupSender } from "./interfaces/hooks/ISablierV2LockupSender.sol";
import { Errors } from "./libraries/Errors.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { Lockup, LockupLinear } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██╗   ██╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██║   ██║╚════██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██║   ██║ █████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║     ╚████╔╝ ███████╗
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝

██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗     ██╗     ██╗███╗   ██╗███████╗ █████╗ ██████╗
██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗    ██║     ██║████╗  ██║██╔════╝██╔══██╗██╔══██╗
██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝    ██║     ██║██╔██╗ ██║█████╗  ███████║██████╔╝
██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝     ██║     ██║██║╚██╗██║██╔══╝  ██╔══██║██╔══██╗
███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║         ███████╗██║██║ ╚████║███████╗██║  ██║██║  ██║
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝         ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝

*/

/// @title SablierV2LockupLinear
/// @notice See the documentation in {ISablierV2LockupLinear}.
contract SablierV2LockupLinear is
    ISablierV2LockupLinear, // one dependency
    SablierV2Lockup // sixteen dependencies
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Counter for stream ids, used in the create functions.
    uint256 private _nextStreamId;

    /// @dev Sablier V2 lockup linear streams mapped by unsigned integers.
    mapping(uint256 id => LockupLinear.Stream stream) private _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param initialNFTDescriptor The address of the initial NFT descriptor.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor
    )
        ERC721("Sablier V2 Lockup Linear NFT", "SAB-V2-LOCKUP-LIN")
        SablierV2Lockup(initialAdmin, initialComptroller, initialNFTDescriptor)
    {
        _nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function getAsset(uint256 streamId) external view override isNotNull(streamId) returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2LockupLinear
    function getCliffTime(uint256 streamId) external view override isNotNull(streamId) returns (uint40 cliffTime) {
        cliffTime = _streams[streamId].cliffTime;
    }

    /// @inheritdoc ISablierV2Lockup
    function getDepositedAmount(uint256 streamId)
        external
        view
        override
        isNotNull(streamId)
        returns (uint128 depositedAmount)
    {
        depositedAmount = _streams[streamId].amounts.deposited;
    }

    /// @inheritdoc ISablierV2Lockup
    function getEndTime(uint256 streamId) external view override isNotNull(streamId) returns (uint40 endTime) {
        endTime = _streams[streamId].endTime;
    }

    /// @inheritdoc ISablierV2LockupLinear
    function getRange(uint256 streamId)
        external
        view
        override
        isNotNull(streamId)
        returns (LockupLinear.Range memory range)
    {
        range = LockupLinear.Range({
            start: _streams[streamId].startTime,
            cliff: _streams[streamId].cliffTime,
            end: _streams[streamId].endTime
        });
    }

    /// @inheritdoc ISablierV2Lockup
    function getRefundedAmount(uint256 streamId)
        external
        view
        override
        isNotNull(streamId)
        returns (uint128 refundedAmount)
    {
        refundedAmount = _streams[streamId].amounts.refunded;
    }

    /// @inheritdoc ISablierV2Lockup
    function getSender(uint256 streamId) external view override isNotNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStartTime(uint256 streamId) external view override isNotNull(streamId) returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStatus(uint256 streamId)
        public
        view
        virtual
        override(ISablierV2Lockup, SablierV2Lockup)
        returns (Lockup.Status status)
    {
        status = _streams[streamId].status;
    }

    /// @inheritdoc ISablierV2LockupLinear
    function getStream(uint256 streamId)
        external
        view
        override
        isNotNull(streamId)
        returns (LockupLinear.Stream memory stream)
    {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2Lockup
    function getWithdrawnAmount(uint256 streamId)
        external
        view
        override
        isNotNull(streamId)
        returns (uint128 withdrawnAmount)
    {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2Lockup
    function isCancelable(uint256 streamId) external view override isNotNull(streamId) returns (bool result) {
        result = _streams[streamId].isCancelable;
    }

    /// @inheritdoc ISablierV2Lockup
    function nextStreamId() external view override returns (uint256) {
        return _nextStreamId;
    }

    /// @inheritdoc ISablierV2Lockup
    function isSettled(uint256 streamId) external view override isNotNull(streamId) returns (bool result) {
        if (_streams[streamId].status == Lockup.Status.ACTIVE) {
            result = _streams[streamId].amounts.deposited == _streamedAmountOf(streamId);
        } else {
            result = true;
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        isNotNull(streamId)
        returns (uint128 refundableAmount)
    {
        // Calculate the refundable amount only if the stream is active; otherwise, it is implicitly zero.
        if (_streams[streamId].status == Lockup.Status.ACTIVE) {
            refundableAmount = _streams[streamId].amounts.deposited - _streamedAmountOf(streamId);
        }
    }

    /// @inheritdoc ISablierV2LockupLinear
    function streamedAmountOf(uint256 streamId)
        public
        view
        override(ISablierV2Lockup, ISablierV2LockupLinear)
        isNotNull(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function withdrawableAmountOf(uint256 streamId)
        public
        view
        override
        isNotNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        withdrawableAmount = _withdrawableAmountOf(streamId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupLinear
    function createWithDurations(LockupLinear.CreateWithDurations calldata params)
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Set the current block timestamp as the stream's start time.
        LockupLinear.Range memory range;
        range.start = uint40(block.timestamp);

        // Calculate the cliff time and the end time. It is safe to use unchecked arithmetic because
        // {_createWithRange} will nonetheless check that the end time is greater than the cliff time,
        // and also that the cliff time is greater than or equal to the start time.
        unchecked {
            range.cliff = range.start + params.durations.cliff;
            range.end = range.start + params.durations.total;
        }
        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithRange(
            LockupLinear.CreateWithRange({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                asset: params.asset,
                cancelable: params.cancelable,
                range: range,
                broker: params.broker
            })
        );
    }

    /// @inheritdoc ISablierV2LockupLinear
    function createWithRange(LockupLinear.CreateWithRange calldata params)
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithRange(params);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierV2Lockup
    function _isCallerStreamSender(uint256 streamId) internal view override returns (bool result) {
        result = msg.sender == _streams[streamId].sender;
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _streamedAmountOf(uint256 streamId) internal view returns (uint128 streamedAmount) {
        Lockup.Status status = _streams[streamId].status;
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Return the withdrawn amount if the stream is depleted.
        if (status == Lockup.Status.DEPLETED) {
            return amounts.withdrawn;
        }
        // Return the deposited amount minus the refunded amount if the stream is canceled.
        else if (status == Lockup.Status.CANCELED) {
            return amounts.deposited - amounts.refunded;
        }

        // Return zero if the cliff time is greater than the current time.
        uint256 currentTime = block.timestamp;
        uint256 cliffTime = uint256(_streams[streamId].cliffTime);
        if (cliffTime > currentTime) {
            return 0;
        }

        // Load the end time.
        uint256 endTime = uint256(_streams[streamId].endTime);

        // Return the deposited amount if the current time is greater than or equal to the end time.
        if (currentTime >= endTime) {
            return amounts.deposited;
        }

        // In all other cases, calculate the amount streamed so far. Normalization to 18 decimals is not needed
        // because there is no mix of amounts with different decimals.
        unchecked {
            // Calculate how much time has passed since the stream started, and the stream's total duration.
            uint256 startTime = uint256(_streams[streamId].startTime);
            UD60x18 elapsedTime = ud(currentTime - startTime);
            UD60x18 totalTime = ud(endTime - startTime);

            // Divide the elapsed time by the stream's total duration.
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);

            // Cast the deposited amount to UD60x18.
            UD60x18 depositedAmount = ud(amounts.deposited);

            // Calculate the streamed amount by multiplying the elapsed time percentage by the deposited amount.
            UD60x18 streamedAmountUd = elapsedTimePercentage.mul(depositedAmount);

            // Although the streamed amount should never exceed the deposited amount, this condition is checked
            // without asserting to avoid locking funds in case of a bug. If this situation occurs, the withdrawn
            // amount is considered to be the streamed amount, and the stream is effectively frozen.
            if (streamedAmountUd.gt(depositedAmount)) {
                return amounts.withdrawn;
            }

            // Cast the streamed amount to uint128. This is safe due to the check above.
            streamedAmount = uint128(streamedAmountUd.intoUint256());
        }
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdrawableAmountOf(uint256 streamId) internal view override returns (uint128 withdrawableAmount) {
        // If the stream is active or canceled, calculate the withdrawable amount by subtracting the withdrawn amount
        // from the streamed amount.
        if (_streams[streamId].status != Lockup.Status.DEPLETED) {
            withdrawableAmount = _streamedAmountOf(streamId) - _streams[streamId].amounts.withdrawn;
        }
        // If the stream is depleted, the withdrawable amount is implicitly zero.
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierV2Lockup
    function _cancel(uint256 streamId) internal override {
        // Checks: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierV2Lockup_StreamNotCancelable(streamId);
        }

        // Calculate the sender's and the recipient's amount.
        uint128 streamedAmount = _streamedAmountOf(streamId);
        uint128 senderAmount = _streams[streamId].amounts.deposited - streamedAmount;
        uint128 recipientAmount = streamedAmount - _streams[streamId].amounts.withdrawn;

        // Checks: the stream is not settled.
        if (senderAmount == 0) {
            revert Errors.SablierV2Lockup_StreamSettled(streamId);
        }

        // Effects: If there are any assets left for the recipient to withdraw, mark the stream as canceled.
        // Otherwise, mark it as depleted.
        _streams[streamId].status = recipientAmount > 0 ? Lockup.Status.CANCELED : Lockup.Status.DEPLETED;
        _streams[streamId].isCancelable = false;

        // Effects: set the refunded amount.
        _streams[streamId].amounts.refunded = senderAmount;

        // Load the sender and the recipient in memory.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Interactions: refund the sender.
        _streams[streamId].asset.safeTransfer({ to: sender, value: senderAmount });

        // Interactions: if `msg.sender` is the sender and the recipient is a contract, try to invoke the cancel
        // hook on the recipient without reverting if the hook is not implemented, and without bubbling up any
        // potential revert.
        if (msg.sender == sender) {
            if (recipient.code.length > 0) {
                try ISablierV2LockupRecipient(recipient).onStreamCanceled({
                    streamId: streamId,
                    senderAmount: senderAmount,
                    recipientAmount: recipientAmount
                }) { } catch { }
            }
        }
        // Interactions: if `msg.sender` is the recipient and the sender is a contract, try to invoke the cancel
        // hook on the sender without reverting if the hook is not implemented, and also without bubbling up any
        // potential revert.
        else {
            if (sender.code.length > 0) {
                try ISablierV2LockupSender(sender).onStreamCanceled({
                    streamId: streamId,
                    senderAmount: senderAmount,
                    recipientAmount: recipientAmount
                }) { } catch { }
            }
        }

        // Log the cancellation.
        emit ISablierV2Lockup.CancelLockupStream(streamId, sender, recipient, senderAmount, recipientAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _createWithRange(LockupLinear.CreateWithRange memory params) internal returns (uint256 streamId) {
        // Safe Interactions: query the protocol fee. This is safe because it's a known Sablier contract that does
        // not call other unknown contracts.
        UD60x18 protocolFee = comptroller.protocolFees(params.asset);

        // Checks: check the fees and calculate the fee amounts.
        Lockup.CreateAmounts memory createAmounts =
            Helpers.checkAndCalculateFees(params.totalAmount, protocolFee, params.broker.fee, MAX_FEE);

        // Checks: validate the user-provided parameters.
        Helpers.checkCreateLinearParams(createAmounts.deposit, params.range);

        // Load the stream id.
        streamId = _nextStreamId;

        // Effects: create the stream.
        _streams[streamId] = LockupLinear.Stream({
            amounts: Lockup.Amounts({ deposited: createAmounts.deposit, refunded: 0, withdrawn: 0 }),
            asset: params.asset,
            cliffTime: params.range.cliff,
            endTime: params.range.end,
            isCancelable: params.cancelable,
            sender: params.sender,
            status: Lockup.Status.ACTIVE,
            startTime: params.range.start
        });

        // Effects: bump the next stream id and record the protocol fee.
        // Using unchecked arithmetic because these calculations cannot realistically overflow, ever.
        unchecked {
            _nextStreamId = streamId + 1;
            protocolRevenues[params.asset] += createAmounts.protocolFee;
        }

        // Effects: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        // Interactions: transfer the deposit and the protocol fee.
        // Using unchecked arithmetic because the deposit and the protocol fee are bounded by the total amount.
        unchecked {
            params.asset.safeTransferFrom({
                from: msg.sender,
                to: address(this),
                value: createAmounts.deposit + createAmounts.protocolFee
            });
        }

        // Interactions: pay the broker fee, if not zero.
        if (createAmounts.brokerFee > 0) {
            params.asset.safeTransferFrom({ from: msg.sender, to: params.broker.account, value: createAmounts.brokerFee });
        }

        // Log the newly created stream.
        emit ISablierV2LockupLinear.CreateLockupLinearStream({
            streamId: streamId,
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: createAmounts,
            asset: params.asset,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker.account
        });
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Checks: the stream is cancelable.
        if (!_streams[streamId].isCancelable) {
            revert Errors.SablierV2Lockup_StreamNotCancelable(streamId);
        }

        // Effects: make the stream not cancelable.
        _streams[streamId].isCancelable = false;

        // Interactions: if the recipient is a contract, try to invoke the renounce hook on the recipient without
        // reverting if the hook is not implemented, and also without bubbling up any potential revert.
        address recipient = _ownerOf(streamId);
        if (recipient.code.length > 0) {
            try ISablierV2LockupRecipient(recipient).onStreamRenounced(streamId) { } catch { }
        }

        // Log the renouncement.
        emit ISablierV2Lockup.RenounceLockupStream(streamId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal override {
        // Effects: update the withdrawn amount.
        _streams[streamId].amounts.withdrawn += amount;

        // Load the amounts in memory.
        Lockup.Amounts memory amounts = _streams[streamId].amounts;

        // Unchecked arithmetic is safe because this calculation has already been performed in {_withdrawableAmountOf}.
        unchecked {
            // Using ">=" instead of "==" for additional safety reasons. In the event of an unforeseen increase in the
            // withdrawn amount, the stream will still be marked as depleted and made not cancelable.
            if (amounts.withdrawn >= amounts.deposited - amounts.refunded) {
                // Effects: mark the stream as depleted.
                _streams[streamId].status = Lockup.Status.DEPLETED;

                // Effects: make the stream not cancelable.
                _streams[streamId].isCancelable = false;
            }
        }

        // Interactions: perform the ERC-20 transfer.
        _streams[streamId].asset.safeTransfer({ to: to, value: amount });

        // Load the recipient in memory.
        address recipient = _ownerOf(streamId);

        // Interactions: if `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try ISablierV2LockupRecipient(recipient).onStreamWithdrawn({
                streamId: streamId,
                caller: msg.sender,
                to: to,
                amount: amount
            }) { } catch { }
        }

        // Log the withdrawal.
        emit ISablierV2Lockup.WithdrawFromLockupStream(streamId, to, amount);
    }
}
