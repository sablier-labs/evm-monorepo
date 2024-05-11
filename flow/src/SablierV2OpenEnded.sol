// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { NoDelegateCall } from "./abstracts/NoDelegateCall.sol";
import { SablierV2OpenEndedState } from "./abstracts/SablierV2OpenEndedState.sol";
import { ISablierV2OpenEnded } from "./interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "./libraries/Errors.sol";
import { OpenEnded } from "./types/DataTypes.sol";

/// @title SablierV2OpenEnded
/// @notice See the documentation in {ISablierV2OpenEnded}.
contract SablierV2OpenEnded is ISablierV2OpenEnded, NoDelegateCall, SablierV2OpenEndedState {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEnded
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notCanceled(streamId)
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        refundableAmount = _refundableAmountOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierV2OpenEnded
    function refundableAmountOf(
        uint256 streamId,
        uint40 time
    )
        external
        view
        override
        notCanceled(streamId)
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        refundableAmount = _refundableAmountOf(streamId, time);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function streamDebtOf(uint256 streamId)
        external
        view
        override
        notCanceled(streamId)
        notNull(streamId)
        returns (uint128 debt)
    {
        uint128 balance = _streams[streamId].balance;
        uint128 streamedAmount = _streamedAmountOf(streamId, uint40(block.timestamp));

        if (balance < streamedAmount) {
            debt = streamedAmount - balance;
        } else {
            return 0;
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function streamedAmountOf(uint256 streamId)
        external
        view
        override
        notCanceled(streamId)
        notNull(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierV2OpenEnded
    function streamedAmountOf(
        uint256 streamId,
        uint40 time
    )
        external
        view
        override
        notCanceled(streamId)
        notNull(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId, time);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawableAmountOf(uint256 streamId)
        external
        view
        override
        notCanceled(streamId)
        notNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        withdrawableAmount = _withdrawableAmountOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawableAmountOf(
        uint256 streamId,
        uint40 time
    )
        external
        view
        override
        notCanceled(streamId)
        notNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        withdrawableAmount = _withdrawableAmountOf(streamId, time);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEnded
    function adjustRatePerSecond(
        uint256 streamId,
        uint128 newRatePerSecond
    )
        external
        override
        noDelegateCall
        notCanceled(streamId)
        notNull(streamId)
        onlySender(streamId)
    {
        // Effects and Interactions: adjust the stream.
        _adjustRatePerSecond(streamId, newRatePerSecond);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function cancel(uint256 streamId)
        public
        override
        noDelegateCall
        notCanceled(streamId)
        notNull(streamId)
        onlySender(streamId)
    {
        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function cancelMultiple(uint256[] calldata streamIds) external override {
        // Iterate over the provided array of stream IDs and cancel each stream.
        uint256 count = streamIds.length;
        for (uint256 i = 0; i < count; ++i) {
            // Effects and Interactions: cancel the stream.
            cancel(streamIds[i]);
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function create(
        address sender,
        address recipient,
        uint128 ratePerSecond,
        IERC20 asset
    )
        external
        override
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, asset);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function createAndDeposit(
        address sender,
        address recipient,
        uint128 ratePerSecond,
        IERC20 asset,
        uint128 amount
    )
        external
        override
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, asset);

        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function createMultiple(
        address[] calldata recipients,
        address[] calldata senders,
        uint128[] calldata ratesPerSecond,
        IERC20 asset
    )
        public
        override
        returns (uint256[] memory streamIds)
    {
        uint256 recipientsCount = recipients.length;
        uint256 sendersCount = senders.length;
        uint256 ratesPerSecondCount = ratesPerSecond.length;

        // Check: count of `senders`, `recipients` and `ratesPerSecond` matches.
        if (recipientsCount != sendersCount || recipientsCount != ratesPerSecondCount) {
            revert Errors.SablierV2OpenEnded_CreateMultipleArrayCountsNotEqual(
                recipientsCount, sendersCount, ratesPerSecondCount
            );
        }

        streamIds = new uint256[](recipientsCount);
        for (uint256 i = 0; i < recipientsCount; ++i) {
            // Checks, Effects and Interactions: create the stream.
            streamIds[i] = _create(senders[i], recipients[i], ratesPerSecond[i], asset);
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function createAndDepositMultiple(
        address[] calldata recipients,
        address[] calldata senders,
        uint128[] calldata ratesPerSecond,
        IERC20 asset,
        uint128[] calldata amounts
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        streamIds = new uint256[](recipients.length);
        streamIds = createMultiple(recipients, senders, ratesPerSecond, asset);

        uint256 streamIdsCount = streamIds.length;
        if (streamIdsCount != amounts.length) {
            revert Errors.SablierV2OpenEnded_DepositArrayCountsNotEqual(streamIdsCount, amounts.length);
        }

        // Deposit on each stream.
        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Checks, Effects and Interactions: deposit on stream.
            _deposit(streamIds[i], amounts[i]);
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function deposit(
        uint256 streamId,
        uint128 amount
    )
        external
        override
        noDelegateCall
        notCanceled(streamId)
        notNull(streamId)
    {
        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function depositMultiple(uint256[] memory streamIds, uint128[] calldata amounts) public override noDelegateCall {
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;

        // Check: count of `streamIds` matches count of `amounts`.
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2OpenEnded_DepositArrayCountsNotEqual(streamIdsCount, amountsCount);
        }

        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Check: the stream is not canceled.
            if (isCanceled(streamIds[i])) {
                revert Errors.SablierV2OpenEnded_StreamCanceled(streamIds[i]);
            }

            // Checks, Effects and Interactions: deposit on stream.
            _deposit(streamIds[i], amounts[i]);
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function restartStream(uint256 streamId, uint128 ratePerSecond) external override {
        // Checks, Effects and Interactions: restart the stream.
        _restartStream(streamId, ratePerSecond);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function restartStreamAndDeposit(uint256 streamId, uint128 ratePerSecond, uint128 amount) external override {
        // Checks, Effects and Interactions: restart the stream.
        _restartStream(streamId, ratePerSecond);

        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function refundFromStream(
        uint256 streamId,
        uint128 amount
    )
        external
        override
        noDelegateCall
        notCanceled(streamId)
        notNull(streamId)
        onlySender(streamId)
    {
        // Checks, Effects and Interactions: make the refund.
        _refundFromStream(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawAt(uint256 streamId, address to, uint40 time) external override {
        // Checks, Effects and Interactions: make the withdrawal.
        _withdrawAt(streamId, to, time);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawAtMultiple(
        uint256[] calldata streamIds,
        uint40[] calldata times
    )
        external
        override
        noDelegateCall
    {
        // Check: there is an equal number of `streamIds` and `amounts`.
        uint256 streamIdsCount = streamIds.length;
        uint256 timesCount = times.length;
        if (streamIdsCount != timesCount) {
            revert Errors.SablierV2OpenEnded_WithdrawMultipleArrayCountsNotEqual(streamIdsCount, timesCount);
        }

        // Iterate over the provided array of stream IDs, and withdraw from each stream to the recipient.
        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Checks, Effects and Interactions: check the parameters and make the withdrawal.
            _withdrawAt({ streamId: streamIds[i], to: _streams[streamIds[i]].recipient, time: times[i] });
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawMax(uint256 streamId, address to) external override {
        // Checks, Effects and Interactions: make the withdrawal.
        _withdrawAt(streamId, to, uint40(block.timestamp));
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the transfer amount based on the asset's decimals.
    /// @dev Changes the amount based on the asset's decimal difference from 18:
    /// - if the asset has fewer decimals, the amount is reduced
    /// - if the asset has more decimals, the amount is increased
    function _calculateTransferAmount(
        uint256 streamId,
        uint128 amount
    )
        internal
        view
        returns (uint128 transferAmount)
    {
        // Retrieve the asset's decimals from storage.
        uint8 assetDecimals = _streams[streamId].assetDecimals;

        // Return the original amount if it's already in the standard 18-decimal format.
        if (assetDecimals == 18) {
            return amount;
        }

        // Determine if the asset's decimals are greater than 18.
        bool isGreaterThan18 = assetDecimals > 18;

        // Calculate the difference in decimals.
        uint8 normalizationFactor = isGreaterThan18 ? assetDecimals - 18 : 18 - assetDecimals;

        // Change the transfer amount based on the decimal difference.
        transferAmount = isGreaterThan18
            ? (amount * (10 ** normalizationFactor)).toUint128()
            : (amount / (10 ** normalizationFactor)).toUint128();
    }

    /// @dev Checks whether the withdrawable amount or the sum of the withdrawable and refundable amounts is greater
    /// than the stream's balance.
    function _checkCalculatedAmount(uint256 streamId, uint128 amount) internal view {
        uint128 balance = _streams[streamId].balance;
        if (amount > balance) {
            revert Errors.SablierV2OpenEnded_InvalidCalculation(streamId, balance, amount);
        }
    }

    /// @dev Calculates the refundable amount.
    function _refundableAmountOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        return _streams[streamId].balance - _withdrawableAmountOf(streamId, time);
    }

    /// @notice Retrieves the asset's decimals safely, defaulting to "0" if an error occurs.
    /// @dev Performs a low-level call to handle assets in which the decimals are not implemented.
    function _safeAssetDecimals(address asset) internal view returns (uint8) {
        (bool success, bytes memory returnData) = asset.staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        if (success && returnData.length == 32) {
            return abi.decode(returnData, (uint8));
        } else {
            return 0;
        }
    }

    /// @dev Calculates the streamed amount.
    function _streamedAmountOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        uint40 lastTimeUpdate = _streams[streamId].lastTimeUpdate;

        // If the time reference is less than or equal to the `lastTimeUpdate`, return zero.
        if (time <= lastTimeUpdate) {
            return 0;
        }

        // Calculate the amount streamed since last update. Each number is normalized to 18 decimals.
        unchecked {
            // Calculate how much time has passed since the last update.
            uint128 elapsedTime = time - lastTimeUpdate;

            // Calculate the streamed amount by multiplying the elapsed time by the rate per second.
            uint128 ratePerSecond = _streams[streamId].ratePerSecond;
            uint128 streamedAmount = elapsedTime * ratePerSecond;

            return streamedAmount;
        }
    }

    /// @dev Calculates the withdrawable amount.
    function _withdrawableAmountOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        uint128 balance = _streams[streamId].balance;

        if (balance == 0) {
            return 0;
        }

        uint128 streamedAmount = _streamedAmountOf(streamId, time);

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
    function _adjustRatePerSecond(uint256 streamId, uint128 newRatePerSecond) internal {
        // Check: the new rate per second is not zero.
        if (newRatePerSecond == 0) {
            revert Errors.SablierV2OpenEnded_RatePerSecondZero();
        }

        uint128 oldRatePerSecond = _streams[streamId].ratePerSecond;

        // Check: the new rate per second is not equal to the actual rate per second.
        if (newRatePerSecond == oldRatePerSecond) {
            revert Errors.SablierV2OpenEnded_RatePerSecondNotDifferent(newRatePerSecond);
        }

        uint128 recipientAmount = _withdrawableAmountOf(streamId, uint40(block.timestamp));

        // Although the withdrawable amount should never exceed the balance, this condition is checked to avoid exploits
        // in case of a bug.
        _checkCalculatedAmount(streamId, recipientAmount);

        // Effect: change the rate per second.
        _streams[streamId].ratePerSecond = newRatePerSecond;

        // Effect: update the stream time.
        _updateTime(streamId, uint40(block.timestamp));

        // Effects and Interactions: withdraw the assets to the recipient, if any assets available.
        if (recipientAmount > 0) {
            _extractFromStream(streamId, _streams[streamId].recipient, recipientAmount);
        }

        // Log the adjustment.
        emit ISablierV2OpenEnded.AdjustOpenEndedStream(
            streamId, _streams[streamId].asset, recipientAmount, oldRatePerSecond, newRatePerSecond
        );
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _cancel(uint256 streamId) internal {
        address recipient = _streams[streamId].recipient;
        address sender = _streams[streamId].sender;
        uint128 balance = _streams[streamId].balance;
        uint128 recipientAmount = _withdrawableAmountOf(streamId, uint40(block.timestamp));

        // Calculate the refundable amount here for gas optimization.
        uint128 senderAmount = balance - recipientAmount;

        // Calculate the sum of the withdrawable and refundable amounts.
        uint128 sum = senderAmount + recipientAmount;

        // Although the sum of the withdrawable and refundable amounts should never exceed the balance, this
        // condition is checked to avoid exploits in case of a bug.
        _checkCalculatedAmount(streamId, sum);

        // Effect: set the stream as canceled.
        _streams[streamId].isCanceled = true;

        // Effect: set the rate per second to zero.
        _streams[streamId].ratePerSecond = 0;

        // Effects and Interactions: refund the sender, if any assets available.
        if (senderAmount > 0) {
            _extractFromStream(streamId, sender, senderAmount);
        }

        // Effects and Interactions: withdraw the assets to the recipient, if any assets available.
        if (recipientAmount > 0) {
            _extractFromStream(streamId, recipient, recipientAmount);
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
        uint128 ratePerSecond,
        IERC20 asset
    )
        internal
        noDelegateCall
        returns (uint256 streamId)
    {
        // Check: the sender is not the zero address.
        if (sender == address(0)) {
            revert Errors.SablierV2OpenEnded_SenderZeroAddress();
        }

        // Check: the recipient is not the zero address.
        if (recipient == address(0)) {
            revert Errors.SablierV2OpenEnded_RecipientZeroAddress();
        }

        // Check: the rate per second is not zero.
        if (ratePerSecond == 0) {
            revert Errors.SablierV2OpenEnded_RatePerSecondZero();
        }

        uint8 assetDecimals = _safeAssetDecimals(address(asset));

        // Check: the asset does not have decimals.
        if (assetDecimals == 0) {
            revert Errors.SablierV2OpenEnded_InvalidAssetDecimals(asset);
        }

        // Load the stream id.
        streamId = nextStreamId;

        // Effect: create the stream.
        _streams[streamId] = OpenEnded.Stream({
            asset: asset,
            assetDecimals: assetDecimals,
            balance: 0,
            isCanceled: false,
            isStream: true,
            lastTimeUpdate: uint40(block.timestamp),
            ratePerSecond: ratePerSecond,
            recipient: recipient,
            sender: sender
        });

        // Effect: bump the next stream id.
        // Using unchecked arithmetic because this calculation cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Log the newly created stream.
        emit ISablierV2OpenEnded.CreateOpenEndedStream(
            streamId, sender, recipient, ratePerSecond, asset, uint40(block.timestamp)
        );
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _deposit(uint256 streamId, uint128 amount) internal {
        // Check: the deposit amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2OpenEnded_DepositAmountZero();
        }

        // Effect: update the stream balance.
        _streams[streamId].balance += amount;

        // Retrieve the ERC-20 asset from storage.
        IERC20 asset = _streams[streamId].asset;

        // Calculate the transfer amount.
        uint128 transferAmount = _calculateTransferAmount(streamId, amount);

        // Interaction: transfer the deposit amount.
        asset.safeTransferFrom(msg.sender, address(this), transferAmount);

        // Log the deposit.
        emit ISablierV2OpenEnded.DepositOpenEndedStream(streamId, msg.sender, asset, amount);
    }

    /// @dev Helper function to update the `balance` and to perform the ERC-20 transfer.
    function _extractFromStream(uint256 streamId, address to, uint128 amount) internal {
        // Effect: update the stream balance.
        _streams[streamId].balance -= amount;

        // Calculate the transfer amount.
        uint128 transferAmount = _calculateTransferAmount(streamId, amount);

        // Interaction: perform the ERC-20 transfer.
        _streams[streamId].asset.safeTransfer(to, transferAmount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _refundFromStream(uint256 streamId, uint128 amount) internal {
        address sender = _streams[streamId].sender;
        uint128 refundableAmount = _refundableAmountOf(streamId, uint40(block.timestamp));

        // Check: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2OpenEnded_RefundAmountZero();
        }

        // Check: the withdraw amount is not greater than the refundable amount.
        if (amount > refundableAmount) {
            revert Errors.SablierV2OpenEnded_Overrefund(streamId, amount, refundableAmount);
        }

        // Effects and interactions: update the `balance` and perform the ERC-20 transfer.
        _extractFromStream(streamId, sender, amount);

        // Log the refund.
        emit ISablierV2OpenEnded.RefundFromOpenEndedStream(streamId, sender, _streams[streamId].asset, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _restartStream(
        uint256 streamId,
        uint128 ratePerSecond
    )
        internal
        noDelegateCall
        notNull(streamId)
        onlySender(streamId)
    {
        // Check: the stream is canceled.
        if (!_streams[streamId].isCanceled) {
            revert Errors.SablierV2OpenEnded_StreamNotCanceled(streamId);
        }

        // Check: the rate per second is not zero.
        if (ratePerSecond == 0) {
            revert Errors.SablierV2OpenEnded_RatePerSecondZero();
        }

        // Effect: set the rate per second.
        _streams[streamId].ratePerSecond = ratePerSecond;

        // Effect: set the stream as not canceled.
        _streams[streamId].isCanceled = false;

        // Effect: update the stream time.
        _updateTime(streamId, uint40(block.timestamp));

        // Log the restart.
        emit ISablierV2OpenEnded.RestartOpenEndedStream(streamId, msg.sender, _streams[streamId].asset, ratePerSecond);
    }

    /// @dev Sets the stream time to the current block timestamp.
    function _updateTime(uint256 streamId, uint40 time) internal {
        _streams[streamId].lastTimeUpdate = time;
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdrawAt(
        uint256 streamId,
        address to,
        uint40 time
    )
        internal
        noDelegateCall
        notCanceled(streamId)
        notNull(streamId)
    {
        // Check: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2OpenEnded_WithdrawToZeroAddress();
        }

        // Retrieve the recipient from storage.
        address recipient = _streams[streamId].recipient;

        // Check: if `msg.sender` is not the stream's recipient, the withdrawal address must be the recipient.
        if (to != recipient && msg.sender != recipient) {
            revert Errors.SablierV2OpenEnded_WithdrawalAddressNotRecipient(streamId, msg.sender, to);
        }

        uint40 lastTimeUpdate = _streams[streamId].lastTimeUpdate;

        // Check: the withdrawal time is greater than the `lastTimeUpdate`.
        if (time <= lastTimeUpdate) {
            revert Errors.SablierV2OpenEnded_WithdrawalTimeNotGreaterThanLastUpdate(time, lastTimeUpdate);
        }

        // Check: the time reference is not in the future.
        if (time > uint40(block.timestamp)) {
            revert Errors.SablierV2OpenEnded_WithdrawalTimeInTheFuture(time, block.timestamp);
        }

        // Check: the stream balance is not zero.
        if (_streams[streamId].balance == 0) {
            revert Errors.SablierV2OpenEnded_WithdrawBalanceZero(streamId);
        }

        // Calculate how much to withdraw based on the time reference.
        uint128 withdrawAmount = _withdrawableAmountOf(streamId, time);

        // Although the withdraw amount should never exceed the balance, this condition is checked to avoid exploits
        // in case of a bug.
        _checkCalculatedAmount(streamId, withdrawAmount);

        // Effect: update the stream time.
        _updateTime(streamId, time);

        // Effects and interactions: update the `balance` and perform the ERC-20 transfer.
        _extractFromStream(streamId, to, withdrawAmount);

        // Log the withdrawal.
        emit ISablierV2OpenEnded.WithdrawFromOpenEndedStream(streamId, to, _streams[streamId].asset, withdrawAmount);
    }
}
