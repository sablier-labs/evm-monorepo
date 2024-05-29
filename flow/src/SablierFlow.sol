// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

import { NoDelegateCall } from "./abstracts/NoDelegateCall.sol";
import { SablierFlowState } from "./abstracts/SablierFlowState.sol";
import { ISablierFlow } from "./interfaces/ISablierFlow.sol";
import { Errors } from "./libraries/Errors.sol";
import { Broker, Flow } from "./types/DataTypes.sol";

/// @title SablierFlow
/// @notice See the documentation in {ISablierFlow}.
contract SablierFlow is
    NoDelegateCall, // 0 inherited components
    ISablierFlow, // 1 inherited components
    SablierFlowState // 7 inherited components
{
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() ERC721("Sablier Flow NFT", "SAB-FLOW") { }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFlow
    function amountOwedOf(uint256 streamId) external view override notNull(streamId) returns (uint128 amountOwed) {
        amountOwed = _amountOwedOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierFlow
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
        uint128 amountOwed = _streams[streamId].remainingAmount + _recentAmountOf(streamId, uint40(block.timestamp));

        // If the stream has debt, return zero.
        if (amountOwed >= balance) {
            return 0;
        }

        // Safe to unchecked because subtraction cannot underflow.
        unchecked {
            uint128 solvencyPeriod = (balance - amountOwed) / _streams[streamId].ratePerSecond;
            depletionTime = uint40(block.timestamp + solvencyPeriod);
        }
    }

    /// @inheritdoc ISablierFlow
    function recentAmountOf(uint256 streamId) external view override notNull(streamId) returns (uint128 recentAmount) {
        recentAmount = _recentAmountOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierFlow
    function recentAmountOf(
        uint256 streamId,
        uint40 time
    )
        external
        view
        override
        notNull(streamId)
        returns (uint128 recentAmount)
    {
        recentAmount = _recentAmountOf(streamId, time);
    }

    /// @inheritdoc ISablierFlow
    function refundableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        refundableAmount = _refundableAmountOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierFlow
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

    /// @inheritdoc ISablierFlow
    function streamDebtOf(uint256 streamId) external view override notNull(streamId) returns (uint128 debt) {
        uint128 balance = _streams[streamId].balance;

        uint128 amountOwed = _amountOwedOf(streamId, uint40(block.timestamp));

        if (balance < amountOwed) {
            debt = amountOwed - balance;
        } else {
            return 0;
        }
    }

    /// @inheritdoc ISablierFlow
    function withdrawableAmountOf(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 withdrawableAmount)
    {
        withdrawableAmount = _withdrawableAmountOf(streamId, uint40(block.timestamp));
    }

    /// @inheritdoc ISablierFlow
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

    /// @inheritdoc ISablierFlow
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
        // Effects and Interactions: adjust the rate per second.
        _adjustRatePerSecond(streamId, newRatePerSecond);
    }

    /// @inheritdoc ISablierFlow
    function create(
        address sender,
        address recipient,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable
    )
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, asset, isTransferable);
    }

    /// @inheritdoc ISablierFlow
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
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, asset, isTransferable);

        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function createAndDepositViaBroker(
        address sender,
        address recipient,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable,
        uint128 totalAmount,
        Broker calldata broker
    )
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, ratePerSecond, asset, isTransferable);

        // Checks, Effects and Interactions: deposit into stream through {depositViaBroker}.
        _depositViaBroker(streamId, totalAmount, broker);
    }

    /// @inheritdoc ISablierFlow
    function deposit(
        uint256 streamId,
        uint128 amount
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function depositAndPause(
        uint256 streamId,
        uint128 amount
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);

        // Checks, Effects and Interactions: pause the stream.
        _pause(streamId);
    }

    function depositViaBroker(
        uint256 streamId,
        uint128 totalAmount,
        Broker calldata broker
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: deposit on stream through broker.
        _depositViaBroker(streamId, totalAmount, broker);
    }

    /// @inheritdoc ISablierFlow
    function pause(uint256 streamId)
        external
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

    /// @inheritdoc ISablierFlow
    function refund(
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
        _refund(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function refundAndPause(
        uint256 streamId,
        uint128 amount
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        notPaused(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: make the refund.
        _refund(streamId, amount);

        // Checks, Effects and Interactions: pause the stream.
        _pause(streamId);
    }

    /// @inheritdoc ISablierFlow
    function restart(
        uint256 streamId,
        uint128 ratePerSecond
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: restart the stream.
        _restart(streamId, ratePerSecond);
    }

    /// @inheritdoc ISablierFlow
    function restartAndDeposit(
        uint256 streamId,
        uint128 ratePerSecond,
        uint128 amount
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        onlySender(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: restart the stream.
        _restart(streamId, ratePerSecond);

        // Checks, Effects and Interactions: deposit on stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierFlow
    function withdrawAt(
        uint256 streamId,
        address to,
        uint40 time
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
        // Retrieve the last time update from storage.
        uint40 lastTimeUpdate = _streams[streamId].lastTimeUpdate;

        // Check: the time reference is greater than `lastTimeUpdate`.
        if (time < lastTimeUpdate) {
            revert Errors.SablierFlow_LastUpdateNotLessThanWithdrawalTime(lastTimeUpdate, time);
        }

        // Check: the withdrawal time is not in the future.
        if (time > uint40(block.timestamp)) {
            revert Errors.SablierFlow_WithdrawalTimeInTheFuture(time, block.timestamp);
        }

        // Checks, Effects and Interactions: make the withdrawal.
        _withdrawAt(streamId, to, time);
    }

    /// @inheritdoc ISablierFlow
    function withdrawMax(
        uint256 streamId,
        address to
    )
        external
        override
        noDelegateCall
        notNull(streamId)
        updateMetadata(streamId)
    {
        // Checks, Effects and Interactions: make the withdrawal.
        _withdrawAt(streamId, to, uint40(block.timestamp));
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the amount owed to the recipient at a given time.
    /// @dev The amount owed is the sum of the stored remaining amount and the recent amount streamed since the last
    /// update. This value is independent of the stream's balance.
    function _amountOwedOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        // Calculate the recent amount streamed since last update.
        uint128 recentAmount = _recentAmountOf(streamId, time);

        // Calculate the total amount that is owed to the recipient.
        return _streams[streamId].remainingAmount + recentAmount;
    }

    /// @notice Calculates the transfer amount based on the asset's decimals.
    /// @dev Changes the amount based on the asset's decimal difference from 18:
    /// - if the asset has fewer decimals, the amount is reduced
    /// - if the asset has more decimals, the amount is increased
    function _calculateTransferAmount(uint128 amount, uint8 assetDecimals) internal pure returns (uint128) {
        // Return the original amount if asset's decimals are already 18.
        if (assetDecimals == 18) {
            return amount;
        }

        if (assetDecimals > 18) {
            uint8 normalizingFactor = assetDecimals - 18;
            return (amount * (10 ** normalizingFactor)).toUint128();
        } else {
            uint8 normalizingFactor = 18 - assetDecimals;
            return (amount / (10 ** normalizingFactor)).toUint128();
        }
    }

    /// @dev Calculates the recent amount streamed since last update. Return 0 if the stream is paused.
    function _recentAmountOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        uint40 lastTimeUpdate = _streams[streamId].lastTimeUpdate;

        // If the stream is paused or the time is less than the `lastTimeUpdate`, return zero.
        if (_streams[streamId].isPaused || time <= lastTimeUpdate) {
            return 0;
        }

        uint128 elapsedTime;

        // Safe to unchecked because subtraction cannot underflow.
        unchecked {
            // Calculate time elapsed since the last update.
            elapsedTime = time - lastTimeUpdate;
        }

        // Calculate the recent amount streamed by multiplying the elapsed time by the rate per second.
        return elapsedTime * _streams[streamId].ratePerSecond;
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

    /// @dev Calculates the amount available to withdraw at provided time. The return value considers stream balance.
    function _withdrawableAmountOf(uint256 streamId, uint40 time) internal view returns (uint128) {
        uint128 balance = _streams[streamId].balance;

        // If the balance is zero, return zero.
        if (balance == 0) {
            return 0;
        }

        uint128 amountOwed = _amountOwedOf(streamId, time);

        // If the stream balance is less than or equal to the amount owed, return the stream balance.
        if (balance < amountOwed) {
            return balance;
        }

        return amountOwed;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _adjustRatePerSecond(uint256 streamId, uint128 newRatePerSecond) internal {
        // Check: the new rate per second is not zero.
        if (newRatePerSecond == 0) {
            revert Errors.SablierFlow_RatePerSecondZero();
        }

        uint128 oldRatePerSecond = _streams[streamId].ratePerSecond;

        // Check: the new rate per second is not equal to the actual rate per second.
        if (newRatePerSecond == oldRatePerSecond) {
            revert Errors.SablierFlow_RatePerSecondNotDifferent(newRatePerSecond);
        }

        // Effect: update the remaining amount.
        _updateRemainingAmount(streamId);

        // Effect: update the stream time.
        _updateTime(streamId, uint40(block.timestamp));

        // Effect: set the new rate per second.
        _streams[streamId].ratePerSecond = newRatePerSecond;

        // Log the adjustment.
        emit ISablierFlow.AdjustFlowStream(
            streamId, oldRatePerSecond, newRatePerSecond, _streams[streamId].remainingAmount
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
            revert Errors.SablierFlow_SenderZeroAddress();
        }

        // Check: the rate per second is not zero.
        if (ratePerSecond == 0) {
            revert Errors.SablierFlow_RatePerSecondZero();
        }

        uint8 assetDecimals = _safeAssetDecimals(address(asset));

        // Check: the asset has decimals.
        if (assetDecimals == 0) {
            revert Errors.SablierFlow_InvalidAssetDecimals(asset);
        }

        // Load the stream id.
        streamId = nextStreamId;

        // Effect: create the stream.
        _streams[streamId] = Flow.Stream({
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

        // Using unchecked arithmetic because this calculation can never realistically overflow.
        unchecked {
            // Effect: bump the next stream id.
            nextStreamId = streamId + 1;
        }

        // Effect: mint the NFT to the recipient.
        _mint({ to: recipient, tokenId: streamId });

        // Log the newly created stream.
        emit ISablierFlow.CreateFlowStream(streamId, sender, recipient, ratePerSecond, asset, uint40(block.timestamp));
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _deposit(uint256 streamId, uint128 amount) internal {
        // Check: the deposit amount is not zero.
        if (amount == 0) {
            revert Errors.SablierFlow_DepositAmountZero();
        }

        // Retrieve the ERC-20 asset from storage.
        IERC20 asset = _streams[streamId].asset;

        // Calculate the transfer amount.
        uint128 transferAmount = _calculateTransferAmount(amount, _streams[streamId].assetDecimals);

        // Effect: update the stream balance.
        _streams[streamId].balance += amount;

        // Interaction: transfer the deposit amount.
        asset.safeTransferFrom(msg.sender, address(this), transferAmount);

        // Log the deposit.
        emit ISablierFlow.DepositFlowStream(streamId, msg.sender, asset, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _depositViaBroker(uint256 streamId, uint128 totalAmount, Broker memory broker) internal {
        // Check: the broker's fee is not greater than `MAX_BROKER_FEE`.
        if (broker.fee.gt(MAX_BROKER_FEE)) {
            revert Errors.SablierFlow_BrokerFeeTooHigh(streamId, broker.fee, MAX_BROKER_FEE);
        }

        // Check: the broker recipient is not the zero address.
        if (broker.account == address(0)) {
            revert Errors.SablierFlow_BrokerAddressZero();
        }

        // Calculate the broker's amount.
        uint128 brokerAmountIn18Decimals = uint128(ud(totalAmount).mul(broker.fee).intoUint256());
        uint128 brokerAmount = _calculateTransferAmount(brokerAmountIn18Decimals, _streams[streamId].assetDecimals);

        // Checks, Effects and Interactions: deposit on stream.
        _deposit({ streamId: streamId, amount: totalAmount - brokerAmountIn18Decimals });

        // Interaction: transfer the broker's amount.
        _streams[streamId].asset.safeTransferFrom(msg.sender, broker.account, brokerAmount);
    }

    /// @dev Helper function to calculate the transfer amount and perform the ERC-20 transfer.
    function _extractFromStream(uint256 streamId, address to, uint128 amount) internal {
        // Calculate the transfer amount.
        uint128 transferAmount = _calculateTransferAmount(amount, _streams[streamId].assetDecimals);

        // Effect: update the stream balance.
        _streams[streamId].balance -= amount;

        // Interaction: perform the ERC-20 transfer.
        _streams[streamId].asset.safeTransfer(to, transferAmount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _pause(uint256 streamId) internal {
        // Effect: update the remaining amount.
        _updateRemainingAmount(streamId);

        // Effect: set the rate per second to zero.
        _streams[streamId].ratePerSecond = 0;

        // Effect: set the stream as paused.
        _streams[streamId].isPaused = true;

        // Log the pause.
        emit ISablierFlow.PauseFlowStream({
            streamId: streamId,
            sender: _streams[streamId].sender,
            recipient: _ownerOf(streamId),
            asset: _streams[streamId].asset,
            amountOwed: _streams[streamId].remainingAmount
        });
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _refund(uint256 streamId, uint128 amount) internal {
        // Check: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierFlow_RefundAmountZero();
        }

        // Calculate the refundable amount.
        uint128 refundableAmount = _refundableAmountOf(streamId, uint40(block.timestamp));

        // Check: the refund amount is not greater than the refundable amount.
        if (amount > refundableAmount) {
            revert Errors.SablierFlow_Overrefund(streamId, amount, refundableAmount);
        }

        // Although the refundable amount should never exceed the balance, this condition is checked
        // to avoid exploits in case of a bug.
        if (amount > _streams[streamId].balance) {
            revert Errors.SablierFlow_InvalidCalculation(streamId, _streams[streamId].balance, amount);
        }

        address sender = _streams[streamId].sender;

        // Effect and Interaction: update the balance and perform the ERC-20 transfer to the sender.
        _extractFromStream(streamId, sender, amount);

        // Log the refund.
        emit ISablierFlow.RefundFromFlowStream(streamId, sender, _streams[streamId].asset, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _restart(uint256 streamId, uint128 ratePerSecond) internal {
        // Check: the stream is paused.
        if (!_streams[streamId].isPaused) {
            revert Errors.SablierFlow_StreamNotPaused(streamId);
        }

        // Check: the rate per second is not zero.
        if (ratePerSecond == 0) {
            revert Errors.SablierFlow_RatePerSecondZero();
        }

        // Effect: update the stream time.
        _updateTime(streamId, uint40(block.timestamp));

        // Effect: set the rate per second.
        _streams[streamId].ratePerSecond = ratePerSecond;

        // Effect: set the stream as not paused.
        _streams[streamId].isPaused = false;

        // Log the restart.
        emit ISablierFlow.RestartFlowStream(streamId, msg.sender, _streams[streamId].asset, ratePerSecond);
    }

    /// @dev Update the remaining amount by adding the recent amount streamed since last time update.
    function _updateRemainingAmount(uint256 streamId) internal {
        // Effect: update the remaining amount.
        _streams[streamId].remainingAmount += _recentAmountOf(streamId, uint40(block.timestamp));
    }

    /// @dev Updates the `lastTimeUpdate` to the specified time.
    function _updateTime(uint256 streamId, uint40 time) internal {
        _streams[streamId].lastTimeUpdate = time;
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdrawAt(uint256 streamId, address to, uint40 time) internal {
        // Check: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierFlow_WithdrawToZeroAddress();
        }

        // Check: if `msg.sender` is neither the stream's recipient nor an approved third party, the withdrawal address
        // must be the recipient.
        if (to != _ownerOf(streamId) && !_isCallerStreamRecipientOrApproved(streamId)) {
            revert Errors.SablierFlow_WithdrawalAddressNotRecipient(streamId, msg.sender, to);
        }

        uint128 balance = _streams[streamId].balance;

        // Check: the stream balance is not zero.
        if (balance == 0) {
            revert Errors.SablierFlow_WithdrawNoFundsAvailable(streamId);
        }

        uint128 amountOwed = _amountOwedOf(streamId, time);
        uint128 withdrawAmount;

        // Safe to use unchecked because subtraction cannot underflow.
        unchecked {
            // If there is debt, the withdraw amount is the balance, and the remaining amount is updated so that we
            // don't lose track of the debt.
            if (amountOwed > balance) {
                withdrawAmount = balance;

                // Effect: update the remaining amount.
                _streams[streamId].remainingAmount = amountOwed - balance;
            }
            // Otherwise, recipient can withdraw the full amount, and the remaining amount must be set to zero.
            else {
                withdrawAmount = amountOwed;

                // Effect: set the remaining amount to zero.
                _streams[streamId].remainingAmount = 0;
            }
        }

        // Effect: update the stream time.
        _updateTime(streamId, time);

        // Effect and Interaction: update the balance and perform the ERC-20 transfer to the recipient.
        _extractFromStream(streamId, to, withdrawAmount);

        // Log the withdrawal.
        emit ISablierFlow.WithdrawFromFlowStream(streamId, to, _streams[streamId].asset, withdrawAmount);
    }
}
