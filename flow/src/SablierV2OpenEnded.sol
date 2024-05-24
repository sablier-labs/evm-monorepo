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
    function depletionTimeOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        notPaused(streamId)
        returns (uint40 depletionTime)
    {
        uint128 balance = _streams[streamId].balance;

        // If the stream balance is zero, return zero.
        if (balance == 0) {
            return 0;
        }

        // Calculate here the recipient amount for gas optimization.
        uint128 recipientAmount =
            _streams[streamId].remainingAmount + _streamedAmountOf(streamId, uint40(block.timestamp));

        // If the stream has debt, return zero.
        if (recipientAmount >= balance) {
            return 0;
        }

        // Safe to unchecked because subtraction cannot underflow.
        unchecked {
            uint128 solvencyPeriod = (balance - recipientAmount) / _streams[streamId].ratePerSecond;
            depletionTime = uint40(block.timestamp + solvencyPeriod);
        }
    }

    /// @inheritdoc ISablierV2OpenEnded
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
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
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        refundableAmount = _refundableAmountOf(streamId, time);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function streamDebtOf(uint256 streamId) external view override notNull(streamId) returns (uint128 debt) {
        uint128 balance = _streams[streamId].balance;

        uint128 streamedAmount = _streamedAmountOf(streamId, uint40(block.timestamp));

        uint128 recipientAmount = streamedAmount + _streams[streamId].remainingAmount;

        if (balance < recipientAmount) {
            debt = recipientAmount - balance;
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
        notPaused(streamId)
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
        notPaused(streamId)
        returns (uint128 streamedAmount)
    {
        streamedAmount = _streamedAmountOf(streamId, time);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function withdrawableAmountOf(uint256 streamId)
        external
        view
        override
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
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Effects and Interactions: adjust the stream.
        _adjustRatePerSecond(streamId, newRatePerSecond);
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
    function deposit(
        uint256 streamId,
        uint128 amount
    )
        public
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2OpenEnded
    function pause(uint256 streamId)
        public
        override
        noDelegateCall
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: pause the stream.
        _pause(streamId);
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
    function withdrawMax(uint256 streamId, address to) external override {
        // Checks, Effects and Interactions: make the withdrawal.
        withdrawAt(streamId, to, uint40(block.timestamp));
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

    /// @dev Checks whether the withdrawable amount or the refundable amounts is greater than the stream's balance.
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

    /// @dev Calculates the streamed amount since last update.
    function _streamedAmountOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        uint40 lastTimeUpdate = _streams[streamId].lastTimeUpdate;

        // If the time reference is less than or equal to the `lastTimeUpdate`, return zero.
        if (time <= lastTimeUpdate) {
            return 0;
        }

        // Calculate the amount streamed since last update. Each value is normalized to 18 decimals.
        unchecked {
            // Calculate how much time has passed since the last update.
            uint128 elapsedTime = time - lastTimeUpdate;

            // Calculate the streamed amount by multiplying the elapsed time by the rate per second.
            uint128 streamedAmount = elapsedTime * _streams[streamId].ratePerSecond;

            return streamedAmount;
        }
    }

    /// @dev Calculates the amount available to withdraw at provided time.
    function _withdrawableAmountOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        uint128 balance = _streams[streamId].balance;

        // If the balance is zero, return zero.
        if (balance == 0) {
            return 0;
        }

        uint128 remainingAmount = _streams[streamId].remainingAmount;

        // If the remaining amount is greater than the balance, return the stream balance.
        if (remainingAmount > balance) {
            return balance;
        }

        // If the stream is paused, return the remaining amount.
        if (_streams[streamId].isPaused) {
            return remainingAmount;
        }

        // Calculate the streamed amount since last update.
        uint128 streamedAmount = _streamedAmountOf(streamId, time);

        uint128 recipientAmount = streamedAmount + remainingAmount;

        // If there has been streamed more than how much is available, return the stream balance.
        if (recipientAmount > balance) {
            return balance;
        } else {
            return recipientAmount;
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

        // Calculate the streamed amount since last update.
        uint128 streamedAmount = _streamedAmountOf(streamId, uint40(block.timestamp));

        // Effect: update the remainingAmount.
        _streams[streamId].remainingAmount += streamedAmount;

        // Effect: update the stream time.
        _updateTime(streamId, uint40(block.timestamp));

        // Effect: update the rate per second.
        _streams[streamId].ratePerSecond = newRatePerSecond;

        // Log the adjustment.
        emit ISablierV2OpenEnded.AdjustOpenEndedStream(streamId, streamedAmount, oldRatePerSecond, newRatePerSecond);
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
            isPaused: false,
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

        // Effect: update the stream balance.
        _streams[streamId].balance -= amount;

        // Interaction: perform the ERC-20 transfer.
        _streams[streamId].asset.safeTransfer(to, transferAmount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _pause(uint256 streamId) internal {
        uint128 recipientAmount = _streamedAmountOf(streamId, uint40(block.timestamp));

        // Effect: sum up the remaining amount that the recipient is able to withdraw.
        _streams[streamId].remainingAmount += recipientAmount;

        // Effect: set the rate per second to zero.
        _streams[streamId].ratePerSecond = 0;

        // Effect: set the stream as paused.
        _streams[streamId].isPaused = true;

        // Log the pause.
        emit ISablierV2OpenEnded.PauseOpenEndedStream({
            streamId: streamId,
            sender: _streams[streamId].sender,
            recipient: _ownerOf(streamId),
            asset: _streams[streamId].asset,
            recipientAmount: recipientAmount
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _refundFromStream(uint256 streamId, uint128 amount) internal {
        // Check: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2OpenEnded_RefundAmountZero();
        }

        // Calculate the refundable amount.
        uint128 refundableAmount = _refundableAmountOf(streamId, uint40(block.timestamp));

        // Check: the refund amount is not greater than the refundable amount.
        if (amount > refundableAmount) {
            revert Errors.SablierV2OpenEnded_Overrefund(streamId, amount, refundableAmount);
        }

        // Although the refund amount should never exceed the available amount in stream, this condition is checked to
        // avoid exploits in case of a bug.
        _checkCalculatedAmount(streamId, amount);

        address sender = _streams[streamId].sender;

        // Interaction: perform the ERC-20 transfer.
        _extractFromStream(streamId, sender, amount);

        // Log the refund.
        emit ISablierV2OpenEnded.RefundFromOpenEndedStream(streamId, sender, _streams[streamId].asset, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _restartStream(uint256 streamId, uint128 ratePerSecond) internal {
        // Check: the stream is paused.
        if (!_streams[streamId].isPaused) {
            revert Errors.SablierV2OpenEnded_StreamNotPaused(streamId);
        }

        // Check: the rate per second is not zero.
        if (ratePerSecond == 0) {
            revert Errors.SablierV2OpenEnded_RatePerSecondZero();
        }

        // Effect: update the stream time.
        _updateTime(streamId, uint40(block.timestamp));

        // Effect: set the rate per second.
        _streams[streamId].ratePerSecond = ratePerSecond;

        // Effect: set the stream as not paused.
        _streams[streamId].isPaused = false;

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

        // Although the withdraw amount should never exceed the available amount in stream, this condition is checked to
        // avoid exploits in case of a bug.
        _checkCalculatedAmount(streamId, withdrawableAmount);

        // Effect: update the stream time.
        _updateTime(streamId, time);

        // Effect: update the remaining amount.
        if (remainingAmount > withdrawableAmount) {
            // If the remaining amount is greater than the withdrawable amount, subtract the withdrawable amount.
            _streams[streamId].remainingAmount -= withdrawableAmount;
        } else {
            // Otherwise, set the remaining amount to zero.
            _streams[streamId].remainingAmount = 0;
        }

        // Interaction: perform the ERC-20 transfer.
        _extractFromStream(streamId, to, withdrawableAmount);

        // Log the withdrawal.
        emit ISablierV2OpenEnded.WithdrawFromOpenEndedStream(streamId, to, _streams[streamId].asset, withdrawableAmount);
    }
}
