// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { NoDelegateCall } from "./abstracts/NoDelegateCall.sol";
import { SablierV2OpenEndedState } from "./abstracts/SablierV2OpenEndedState.sol";
import { ISablierV2OpenEnded } from "./interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "./libraries/Errors.sol";
import { OpenEnded } from "./types/DataTypes.sol";

/// @title SablierV2OpenEnded
/// @notice See the documentation in {ISablierV2OpenEnded}.
contract SablierV2OpenEnded is
    NoDelegateCall, // 0 inherited components
    ISablierV2OpenEnded, // 1 inherited components
    SablierV2OpenEndedState // 7 inherited components
{
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() ERC721("Sablier V2 Open Ended NFT", "SAB-V2-OPEN-EN") { }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2OpenEnded
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        notCanceled(streamId)
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
        notNull(streamId)
        notCanceled(streamId)
        returns (uint128 refundableAmount)
    {
        refundableAmount = _refundableAmountOf(streamId, time);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function streamDebtOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        notCanceled(streamId)
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
        notNull(streamId)
        notCanceled(streamId)
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
        notNull(streamId)
        notCanceled(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId, time);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawableAmountOf(uint256 streamId) external view override returns (uint128 withdrawableAmount) {
        withdrawableAmount = withdrawableAmountOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawableAmountOf(
        uint256 streamId,
        uint40 time
    )
        public
        view
        override
        notNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        uint128 remainingAmount = _streams[streamId].remainingAmount;

        // If the stream is canceled, return the remaining amount.
        if (_streams[streamId].isCanceled) {
            return remainingAmount;
        }
        // Otherwise, calculate the withdrawable amount and sum it with the remaining amount.
        else {
            withdrawableAmount = _withdrawableAmountOf(streamId, time) + remainingAmount;
        }
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
        notNull(streamId)
        notCanceled(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Effects and Interactions: adjust the stream.
        _adjustRatePerSecond(streamId, newRatePerSecond);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function cancel(uint256 streamId)
        public
        override
        noDelegateCall
        notNull(streamId)
        notCanceled(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: cancel the stream.
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
        IERC20 asset,
        bool isTransferable
    )
        public
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, asset, isTransferable);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function createAndDeposit(
        address sender,
        address recipient,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable,
        uint128 amount
    )
        external
        override
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = create(sender, recipient, ratePerSecond, asset, isTransferable);

        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function createMultiple(
        address[] calldata recipients,
        address[] calldata senders,
        uint128[] calldata ratesPerSecond,
        IERC20 asset,
        bool[] calldata isTransferable
    )
        public
        override
        noDelegateCall
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
            streamIds[i] = _create(senders[i], recipients[i], ratesPerSecond[i], asset, isTransferable[i]);
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function createAndDepositMultiple(
        address[] calldata recipients,
        address[] calldata senders,
        uint128[] calldata ratesPerSecond,
        IERC20 asset,
        bool[] calldata isTransferable,
        uint128[] calldata amounts
    )
        external
        override
        returns (uint256[] memory streamIds)
    {
        streamIds = new uint256[](recipients.length);
        streamIds = createMultiple(recipients, senders, ratesPerSecond, asset, isTransferable);

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
        public
        override
        noDelegateCall
        notNull(streamId)
        notCanceled(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function depositMultiple(uint256[] memory streamIds, uint128[] calldata amounts) external override {
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;

        // Check: count of `streamIds` matches count of `amounts`.
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2OpenEnded_DepositArrayCountsNotEqual(streamIdsCount, amountsCount);
        }

        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Checks, Effects and Interactions: deposit on stream.
            deposit(streamIds[i], amounts[i]);
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function restartStream(
        uint256 streamId,
        uint128 ratePerSecond
    )
        public
        override
        noDelegateCall
        notNull(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: restart the stream.
        _restartStream(streamId, ratePerSecond);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function restartStreamAndDeposit(uint256 streamId, uint128 ratePerSecond, uint128 amount) external override {
        // Checks, Effects and Interactions: restart the stream.
        restartStream(streamId, ratePerSecond);

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
        notNull(streamId)
        notCanceled(streamId)
        onlySender(streamId)
    {
        // Checks, Effects and Interactions: make the refund.
        _refundFromStream(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawAt(
        uint256 streamId,
        address to,
        uint40 time
    )
        public
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
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
            withdrawAt({ streamId: streamIds[i], to: _ownerOf(streamIds[i]), time: times[i] });
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawMax(uint256 streamId, address to) external override {
        // Checks, Effects and Interactions: make the withdrawal.
        withdrawAt(streamId, to, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawMaxMultiple(uint256[] calldata streamIds) external override {
        uint256 streamIdsCount = streamIds.length;
        uint40 blockTimestamp = uint40(block.timestamp);

        // Iterate over the provided array of stream IDs, and withdraw from each stream to the recipient.
        for (uint256 i = 0; i < streamIdsCount; ++i) {
            // Checks, Effects and Interactions: check the parameters and make the withdrawal.
            withdrawAt({ streamId: streamIds[i], to: _ownerOf(streamIds[i]), time: blockTimestamp });
        }
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

        // Return the original amount if it's already in the 18-decimal format.
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
            uint128 streamedAmount = elapsedTime * _streams[streamId].ratePerSecond;

            return streamedAmount;
        }
    }

    /// @dev Calculates the withdrawable amount without looking at the stream's remaining amount.
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

        // Effect: sum up the remaining amount that the recipient is able to withdraw.
        _streams[streamId].remainingAmount += recipientAmount;

        // Effect: subtract the recipient amount from the stream balance.
        _streams[streamId].balance -= recipientAmount;

        // Effect: change the rate per second.
        _streams[streamId].ratePerSecond = newRatePerSecond;

        // Effect: update the stream time.
        _updateTime(streamId, uint40(block.timestamp));

        // Log the adjustment.
        emit ISablierV2OpenEnded.AdjustOpenEndedStream(streamId, recipientAmount, oldRatePerSecond, newRatePerSecond);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _cancel(uint256 streamId) internal {
        uint128 balance = _streams[streamId].balance;
        address recipient = _ownerOf(streamId);
        uint128 recipientAmount = _withdrawableAmountOf(streamId, uint40(block.timestamp));
        address sender = _streams[streamId].sender;

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

        // Effect: sum up the remaining amount that the recipient is able to withdraw.
        _streams[streamId].remainingAmount += recipientAmount;

        // Effect: set the stream balance to zero.
        _streams[streamId].balance = 0;

        // Interaction: perform the ERC-20 transfer, if any assets available.
        if (senderAmount > 0) {
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
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable
    )
        internal
        returns (uint256 streamId)
    {
        // Check: the sender is not the zero address.
        if (sender == address(0)) {
            revert Errors.SablierV2OpenEnded_SenderZeroAddress();
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
            isTransferable: isTransferable,
            lastTimeUpdate: uint40(block.timestamp),
            ratePerSecond: ratePerSecond,
            remainingAmount: 0,
            sender: sender
        });

        // Effect: bump the next stream id.
        // Using unchecked arithmetic because this calculation cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Effect: mint the NFT to the recipient.
        _mint({ to: recipient, tokenId: streamId });

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

    /// @dev Helper function to calculate the transfer amount and to perform the ERC-20 transfer.
    function _extractFromStream(uint256 streamId, address to, uint128 amount) internal {
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

        // Check: the refund amount is not greater than the refundable amount.
        if (amount > refundableAmount) {
            revert Errors.SablierV2OpenEnded_Overrefund(streamId, amount, refundableAmount);
        }

        // Although the refund amount should never exceed the available amount in stream, this condition is checked to
        // avoid exploits in case of a bug.
        _checkCalculatedAmount(streamId, amount);

        // Effect: update the stream balance.
        _streams[streamId].balance -= amount;

        // Interaction: perform the ERC-20 transfer.
        _extractFromStream(streamId, sender, amount);

        // Log the refund.
        emit ISablierV2OpenEnded.RefundFromOpenEndedStream(streamId, sender, _streams[streamId].asset, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _restartStream(uint256 streamId, uint128 ratePerSecond) internal {
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
    function _withdrawAt(uint256 streamId, address to, uint40 time) internal {
        // Check: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2OpenEnded_WithdrawToZeroAddress();
        }

        // Retrieve the recipient from storage.
        address recipient = _ownerOf(streamId);

        // Check: if `msg.sender` is neither the stream's recipient nor an approved third party, the withdrawal address
        // must be the recipient.
        if (to != recipient && !_isCallerStreamRecipientOrApproved(streamId)) {
            revert Errors.SablierV2OpenEnded_WithdrawalAddressNotRecipient(streamId, msg.sender, to);
        }

        // Retrieve the last time update from storage.
        uint40 lastTimeUpdate = _streams[streamId].lastTimeUpdate;

        // Check: the `lastTimeUpdate` is less than withdrawal time.
        if (time < lastTimeUpdate) {
            revert Errors.SablierV2OpenEnded_LastUpdateNotLessThanWithdrawalTime(lastTimeUpdate, time);
        }

        // Check: the withdrawal time is not in the future.
        if (time > uint40(block.timestamp)) {
            revert Errors.SablierV2OpenEnded_WithdrawalTimeInTheFuture(time, block.timestamp);
        }

        // Retrieve the remaining amount from storage.
        uint128 remainingAmount = _streams[streamId].remainingAmount;

        // Check: the stream balance and the remaining amount are not zero.
        if (_streams[streamId].balance == 0 && remainingAmount == 0) {
            revert Errors.SablierV2OpenEnded_WithdrawNoFundsAvailable(streamId);
        }

        // Calculate the withdrawable amount.
        uint128 withdrawableAmount = _withdrawableAmountOf(streamId, time);

        // Calculate the sum of the withdrawable amount and the remaining amount.
        uint128 sum = withdrawableAmount + remainingAmount;

        // Although the withdraw amount should never exceed the available amount in stream, this condition is checked to
        // avoid exploits in case of a bug.
        _checkCalculatedAmount(streamId, withdrawableAmount);

        // Effect: update the stream time.
        _updateTime(streamId, time);

        // Effect: Set the remaining amount to zero.
        _streams[streamId].remainingAmount = 0;

        // Effect: update the stream balance.
        _streams[streamId].balance -= withdrawableAmount;

        // Interaction: perform the ERC-20 transfer.
        _extractFromStream(streamId, to, sum);

        // Log the withdrawal.
        emit ISablierV2OpenEnded.WithdrawFromOpenEndedStream(streamId, to, _streams[streamId].asset, sum);
    }
}
