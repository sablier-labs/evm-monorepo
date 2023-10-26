// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { NoDelegateCall } from "./abstracts/NoDelegateCall.sol";
import { Errors } from "./libraries/Errors.sol";
import { OpenEnded } from "./types/DataTypes.sol";

import { ISablierV2OpenEnded } from "./interfaces/ISablierV2OpenEnded.sol";

contract SablierV2OpenEnded is ISablierV2OpenEnded, NoDelegateCall {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a canceled stream.
    modifier notCanceled(uint256 streamId) {
        if (wasCanceled(streamId)) {
            revert Errors.SablierV2OpenEnded_StreamCanceled(streamId);
        }
        _;
    }

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        if (!isStream(streamId)) {
            revert Errors.SablierV2OpenEnded_Null(streamId);
        }
        _;
    }

    /// @dev Checks the `msg.sender` is the stream's sender.
    modifier onlySender(uint256 streamId) {
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierV2OpenEnded_Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                USER-FACING STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEnded
    uint256 public override nextStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 OpenEnded streams mapped by unsigned integers.
    mapping(uint256 id => OpenEnded.Stream stream) private _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEnded
    function getAmountPerSecond(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 amountPerSecond)
    {
        amountPerSecond = _streams[streamId].amountPerSecond;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function getAsset(uint256 streamId) external view override notNull(streamId) returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function getBalance(uint256 streamId) external view override notNull(streamId) returns (uint128 balance) {
        balance = _streams[streamId].balance;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function getLastTimeUpdate(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint40 lastTimeUpdate)
    {
        lastTimeUpdate = _streams[streamId].lastTimeUpdate;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function getRecipient(uint256 streamId) external view override notNull(streamId) returns (address recipient) {
        recipient = _streams[streamId].recipient;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function getSender(uint256 streamId) external view notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function getStream(uint256 streamId) external view notNull(streamId) returns (OpenEnded.Stream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2OpenEnded
    function isStream(uint256 streamId) public view returns (bool result) {
        result = _streams[streamId].isStream;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        refundableAmount = _refundableAmountOf(streamId);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function streamDebt(uint256 streamId) external view notNull(streamId) returns (uint128 debt) {
        int256 balance = int256(uint256(_streams[streamId].balance));
        int256 streamedAmount = int256(uint256(_streamedAmountOf(streamId)));
        int256 delta = balance - streamedAmount;

        if (delta >= 0) {
            return 0;
        }

        debt = uint128(uint256(-delta));
    }

    /// @inheritdoc ISablierV2OpenEnded
    function streamedAmountOf(uint256 streamId) external view notNull(streamId) returns (uint128 streamedAmount) {
        streamedAmount = _streamedAmountOf(streamId);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function wasCanceled(uint256 streamId) public view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].wasCanceled;
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawableAmountOf(uint256 streamId)
        external
        view
        notNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        withdrawableAmount = _withdrawableAmountOf(streamId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEnded
    function adjustAmountPerSecond(
        uint256 streamId,
        uint128 newAmountPerSecond
    )
        external
        noDelegateCall
        notCanceled(streamId)
        onlySender(streamId)
    {
        // Effects and Interactions: adjust the stream.
        _adjustAmountPerSecond(streamId, newAmountPerSecond);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function cancel(uint256 streamId) external noDelegateCall notCanceled(streamId) onlySender(streamId) {
        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function create(
        address sender,
        address recipient,
        uint128 amountPerSecond,
        IERC20 asset
    )
        external
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, amountPerSecond, asset);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function createAndDeposit(
        address sender,
        address recipient,
        uint128 amountPerSecond,
        IERC20 asset,
        uint128 depositAmount
    )
        external
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, amountPerSecond, asset);

        // Checks, Effects and Interactions: deposit on the stream.
        _deposit(streamId, depositAmount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function deposit(uint256 streamId, uint128 amount) external noDelegateCall notCanceled(streamId) {
        // Checks, Effects and Interactions: deposit on the stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function depositMultiple(uint256[] calldata streamIds, uint128[] calldata amounts) external noDelegateCall {
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;

        // Checks: count of `streamIds` matches count of `amounts`.
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2OpenEnded_DepositArrayCountsNotEqual(streamIdsCount, amountsCount);
        }

        uint256 streamId;
        uint128 amount;
        for (uint256 i = 0; i < streamIdsCount;) {
            streamId = streamIds[i];
            amount = amounts[i];

            // Checks, Effects and Interactions: deposit on the stream.
            _deposit(streamId, amount);

            // Increment the for loop iterator.
            unchecked {
                i += 1;
            }
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function refundFromStream(
        uint256 streamId,
        uint128 amount
    )
        external
        noDelegateCall
        notCanceled(streamId)
        onlySender(streamId)
    {
        _refundFromStream(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdraw(uint256 streamId, address to, uint128 amount) external noDelegateCall notCanceled(streamId) {
        _withdraw(streamId, to, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `msg.sender` is the stream's sender.
    /// @param streamId The stream id for the query.
    function _isCallerStreamSender(uint256 streamId) internal view returns (bool) {
        return msg.sender == _streams[streamId].sender;
    }

    /// @dev Calculates the refundable amount.
    function _refundableAmountOf(uint256 streamId) internal view returns (uint128) {
        return _streams[streamId].balance - _withdrawableAmountOf(streamId);
    }

    /// @dev Calculates the streamed amount.
    function _streamedAmountOf(uint256 streamId) internal view returns (uint128) {
        uint256 currentTime = block.timestamp;
        uint256 lastTimeUpdate = uint256(_streams[streamId].lastTimeUpdate);

        // Calculate the amount streamed since last update. Normalization to 18 decimals is not needed
        // because there is no mix of amounts with different decimals.
        unchecked {
            // Calculate how much time has passed since the last update.
            UD60x18 elapsedTime = ud(currentTime - lastTimeUpdate);

            // Calculate the streamed amount by multiplying the elapsed time by the amount per second.
            UD60x18 amountPerSecond = ud(_streams[streamId].amountPerSecond);
            UD60x18 streamedAmount = elapsedTime.mul(amountPerSecond);

            return uint128(streamedAmount.intoUint256());
        }
    }

    /// @dev Calculates the withdrawable amount.
    function _withdrawableAmountOf(uint256 streamId) internal view returns (uint128) {
        uint128 balance = _streams[streamId].balance;

        if (balance == 0) {
            return 0;
        }

        uint128 streamedAmount = _streamedAmountOf(streamId);

        // If there has been streamed more than how much is available, return the stream balance.
        if (streamedAmount >= balance) {
            return balance;
        } else {
            return streamedAmount;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _adjustAmountPerSecond(uint256 streamId, uint128 newAmountPerSecond) internal {
        // Checks: the amount per second is not zero.
        if (newAmountPerSecond == 0) {
            revert Errors.SablierV2OpenEnded_AmountPerSecondZero();
        }

        uint128 recipientAmount = _withdrawableAmountOf(streamId);
        uint128 oldAmountPerSecond = _streams[streamId].amountPerSecond;

        // Effects: update the stream time.
        _updateTime(streamId);

        // Effects: change the amount per second.
        _streams[streamId].amountPerSecond = newAmountPerSecond;

        if (recipientAmount > 0) {
            // Effects and interactions: update the `balance` and perform the ERC-20 transfer.
            _extractFromStream(streamId, _streams[streamId].recipient, recipientAmount);
        }

        // Log the adjustment.
        emit ISablierV2OpenEnded.AdjustOpenEndedStream(
            streamId, recipientAmount, oldAmountPerSecond, newAmountPerSecond
        );
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _cancel(uint256 streamId) internal {
        address recipient = _streams[streamId].recipient;
        address sender = _streams[streamId].sender;
        uint128 balance = _streams[streamId].balance;
        uint128 recipientAmount = _withdrawableAmountOf(streamId);

        // Calculate the refundable amount here for gas optimization.
        uint128 senderAmount = balance - recipientAmount;

        // Although the sum of the withdrawable and refundable amounts should never exceed the balance, this
        // condition is checked to avoid exploits in case of a bug.
        uint128 sum = senderAmount + recipientAmount;
        if (sum > balance) {
            revert Errors.SablierV2OpenEnded_CancelInvalidCalculation(streamId, balance, senderAmount, recipientAmount);
        }
        // In case there is a rounding error and the sum is less than the balance, the sender receives the remainder.
        else if (sum < balance) {
            uint128 delta = balance - sum;
            senderAmount += delta;
        }

        // Effects: mark the stream as canceled.
        _streams[streamId].wasCanceled = true;

        // Effects: set the amount per second to zero.
        _streams[streamId].amountPerSecond = 0;

        // Interactions: refund the sender, if any assets available.
        if (senderAmount > 0) {
            _extractFromStream(streamId, sender, senderAmount);
        }

        // Interactions: withdraw the assets to the recipient, if any assets available.
        if (recipientAmount > 0) {
            _extractFromStream(streamId, sender, senderAmount);
        }

        // Log the cancellation.
        emit ISablierV2OpenEnded.CancelOpenEndedStream(
            streamId, sender, recipient, _streams[streamId].asset, senderAmount, recipientAmount
        );
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _create(
        address sender,
        address recipient,
        uint128 amountPerSecond,
        IERC20 asset
    )
        internal
        returns (uint256 streamId)
    {
        // Checks: the sender is not the zero address.
        if (sender == address(0)) {
            revert Errors.SablierV2OpenEnded_SenderZeroAddress();
        }

        // Checks: the recipient is not the zero address.
        if (recipient == address(0)) {
            revert Errors.SablierV2OpenEnded_RecipientZeroAddress();
        }

        // Checks: the amount per second is not zero.
        if (amountPerSecond == 0) {
            revert Errors.SablierV2OpenEnded_AmountPerSecondZero();
        }

        // Load the stream id.
        streamId = nextStreamId;

        // Effects: create the stream.
        _streams[streamId] = OpenEnded.Stream({
            amountPerSecond: amountPerSecond,
            asset: asset,
            balance: 0,
            isStream: true,
            lastTimeUpdate: uint40(block.timestamp),
            recipient: recipient,
            sender: sender,
            wasCanceled: false
        });

        // Effects: bump the next stream id.
        // Using unchecked arithmetic because these calculations cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Log the newly created stream.
        emit ISablierV2OpenEnded.CreateOpenEndedStream(
            streamId, sender, recipient, amountPerSecond, asset, uint40(block.timestamp)
        );
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _deposit(uint256 streamId, uint128 amount) internal {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2OpenEnded_DepositAmountZero();
        }

        // Effects: update the stream balance.
        _streams[streamId].balance += amount;

        // Retrieve the ERC-20 asset from storage.
        IERC20 asset = _streams[streamId].asset;

        // Interactions: transfer the deposit amount.
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Log the deposit.
        emit ISablierV2OpenEnded.DepositOpenEndedStream(streamId, msg.sender, asset, amount);
    }

    /// @dev Helper function to update the `balance` and to perform the ERC-20 transfer.
    function _extractFromStream(uint256 streamId, address to, uint128 amount) internal {
        // Effects: update the stream balance.
        _streams[streamId].balance -= amount;

        // Interactions: perform the ERC-20 transfer.
        _streams[streamId].asset.safeTransfer(to, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _refundFromStream(uint256 streamId, uint128 amount) internal {
        address sender = _streams[streamId].sender;
        uint128 senderAmount = _refundableAmountOf(streamId);

        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2OpenEnded_AmountZero(streamId);
        }

        // Checks: the amount is not greater than what is available.
        if (amount > senderAmount) {
            revert Errors.SablierV2OpenEnded_Overdraw(streamId, amount, senderAmount);
        }

        // Effects and interactions: update the `balance` and perform the ERC-20 transfer.
        _extractFromStream(streamId, sender, amount);

        // Log the refund.
        emit ISablierV2OpenEnded.RefundFromOpenEndedStream(streamId, sender, _streams[streamId].asset, amount);
    }

    /// @dev Sets the stream time to the current block timestamp.
    function _updateTime(uint256 streamId) internal {
        _streams[streamId].lastTimeUpdate = uint40(block.timestamp);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal {
        bool isCallerStreamSender = _isCallerStreamSender(streamId);
        address recipient = _streams[streamId].recipient;

        // Checks: `msg.sender` is the stream's sender or the stream's recipient.
        if (!isCallerStreamSender && !(msg.sender == recipient)) {
            revert Errors.SablierV2OpenEnded_Unauthorized(streamId, msg.sender);
        }

        // Checks: the provided address is the recipient if `msg.sender` is the sender of the stream.
        if (isCallerStreamSender && to != recipient) {
            revert Errors.SablierV2OpenEnded_Unauthorized(streamId, msg.sender);
        }

        // Checks: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2OpenEnded_WithdrawToZeroAddress();
        }

        uint128 recipientAmount = _withdrawableAmountOf(streamId);

        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2OpenEnded_AmountZero(streamId);
        }

        // Checks: the amount is not greater than what is available.
        if (amount > recipientAmount) {
            revert Errors.SablierV2OpenEnded_Overdraw(streamId, amount, recipientAmount);
        }

        // Effects: update the stream time.
        _updateTime(streamId);

        // Effects and interactions: update the `balance` and perform the ERC-20 transfer.
        _extractFromStream(streamId, to, amount);

        // Log the withdrawal.
        emit ISablierV2OpenEnded.WithdrawFromOpenEndedStream(streamId, to, _streams[streamId].asset, amount);
    }
}
