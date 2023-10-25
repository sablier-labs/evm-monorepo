// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { Payroll } from "./libraries/DataTypes.sol";
import { Errors } from "./libraries/Errors.sol";

import { ISablierV2Payroll } from "./interfaces/ISablierV2Payroll.sol";

contract SablierV2Payroll is ISablierV2Payroll {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `streamId` does not reference a canceled stream.
    modifier notCanceled(uint256 streamId) {
        if (wasCanceled(streamId)) {
            revert Errors.SablierV2Payroll_StreamCanceled(streamId);
        }
        _;
    }

    /// @dev Checks that `streamId` does not reference a null stream.
    modifier notNull(uint256 streamId) {
        if (!isStream(streamId)) {
            revert Errors.SablierV2Payroll_Null(streamId);
        }
        _;
    }

    /// @dev Checks the `msg.sender` is the stream's sender.
    modifier onlySender(uint256 streamId) {
        if (!_isCallerStreamSender(streamId)) {
            revert Errors.SablierV2Payroll_Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                USER-FACING STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Payroll
    uint256 public override nextStreamId;

    /*//////////////////////////////////////////////////////////////////////////
                                  PRIVATE STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 Payroll streams mapped by unsigned integers.
    mapping(uint256 id => Payroll.Stream stream) private _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Payroll
    function getAmountPerSecond(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint128 amountPerSecond)
    {
        amountPerSecond = _streams[streamId].amountPerSecond;
    }

    /// @inheritdoc ISablierV2Payroll
    function getAsset(uint256 streamId) external view override notNull(streamId) returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2Payroll
    function getBalance(uint256 streamId) external view override notNull(streamId) returns (uint128 balance) {
        balance = _streams[streamId].balance;
    }

    /// @inheritdoc ISablierV2Payroll
    function getLastTimeUpdate(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (uint40 lastTimeUpdate)
    {
        lastTimeUpdate = _streams[streamId].lastTimeUpdate;
    }

    /// @inheritdoc ISablierV2Payroll
    function getRecipient(uint256 streamId) external view override notNull(streamId) returns (address recipient) {
        recipient = _streams[streamId].recipient;
    }

    /// @inheritdoc ISablierV2Payroll
    function getSender(uint256 streamId) external view notNull(streamId) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2Payroll
    function getStream(uint256 streamId) external view notNull(streamId) returns (Payroll.Stream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2Payroll
    function isStream(uint256 streamId) public view returns (bool result) {
        result = _streams[streamId].isStream;
    }

    /// @inheritdoc ISablierV2Payroll
    function refundableAmountOf(uint256 streamId)
        public
        view
        override
        notNull(streamId)
        returns (uint128 refundableAmount)
    {
        // Invariant: balance >= withdrawableAmount
        refundableAmount = _streams[streamId].balance - withdrawableAmountOf(streamId);
    }

    /// @inheritdoc ISablierV2Payroll
    function senderDebt(uint256 streamId) external view notNull(streamId) returns (uint128 debt) {
        int256 balance = int256(uint256(_streams[streamId].balance));
        int256 streamedAmount = int256(uint256(streamedAmountOf(streamId)));
        int256 delta = balance - streamedAmount;

        if (delta >= 0) {
            return 0;
        }

        debt = uint128(uint256(-delta));
    }

    /// @inheritdoc ISablierV2Payroll
    function streamedAmountOf(uint256 streamId)
        public
        view
        override
        notNull(streamId)
        returns (uint128 streamedAmount)
    {
        // Invariant: lastTimeUpdate <= block.timestamp;
        uint256 currentTime = block.timestamp;
        uint256 lastTimeUpdate = uint256(_streams[streamId].lastTimeUpdate);

        // Calculate the amount streamed since last update. Normalization to 18 decimals is not needed
        // because there is no mix of amounts with different decimals.
        unchecked {
            // Calculate how much time has passed since the last update.
            UD60x18 elapsedTime = ud(currentTime - lastTimeUpdate);

            // Calculate the streamed amount by multiplying the elapsed time by the amount per second.
            UD60x18 amountPerSecond = ud(_streams[streamId].amountPerSecond);
            UD60x18 _streamedAmount = elapsedTime.mul(amountPerSecond);

            streamedAmount = uint128(UD60x18.unwrap(_streamedAmount));
        }
    }

    /// @inheritdoc ISablierV2Payroll
    function wasCanceled(uint256 streamId) public view override notNull(streamId) returns (bool result) {
        result = _streams[streamId].wasCanceled;
    }

    /// @inheritdoc ISablierV2Payroll
    function withdrawableAmountOf(uint256 streamId) public view returns (uint128 withdrawableAmount) {
        uint128 balance = _streams[streamId].balance;
        uint128 streamedAmount = streamedAmountOf(streamId);

        if (balance == 0) {
            return 0;
        }

        // If there has been streamed more than how much is available, return the stream balance.
        if (streamedAmount >= balance) {
            return balance;
        } else {
            withdrawableAmount = streamedAmount;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Payroll
    function adjustStream(
        uint256 streamId,
        uint128 newAmountPerSecond
    )
        external
        notCanceled(streamId)
        onlySender(streamId)
    {
        // Checks: the amount per second is not zero.
        if (newAmountPerSecond == 0) {
            revert Errors.SablierV2Payroll_AmountPerSecondZero();
        }

        // Effects and Interactions: adjust the stream.
        _adjustStream(streamId, newAmountPerSecond);
    }

    /// @inheritdoc ISablierV2Payroll
    function cancel(uint256 streamId) external notCanceled(streamId) onlySender(streamId) {
        _cancel(streamId);
    }

    /// @inheritdoc ISablierV2Payroll
    function create(
        address recipient,
        address sender,
        uint128 amountPerSecond,
        IERC20 asset
    )
        external
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(recipient, sender, amountPerSecond, asset);
    }

    /// @inheritdoc ISablierV2Payroll
    function createAndDeposit(
        address recipient,
        address sender,
        uint128 amountPerSecond,
        IERC20 asset,
        uint128 depositAmount
    )
        external
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(recipient, sender, amountPerSecond, asset);

        // Checks, Effects and Interactions: deposit on the stream.
        _deposit(streamId, depositAmount);
    }

    /// @inheritdoc ISablierV2Payroll
    function deposit(uint256 streamId, uint128 amount) external {
        // Checks, Effects and Interactions: deposit on the stream.
        _deposit(streamId, amount);
    }

    /// @inheritdoc ISablierV2Payroll
    function depositMultiple(uint256[] calldata streamIds, uint128[] calldata amounts) external {
        uint256 streamIdsCount = streamIds.length;
        uint256 amountsCount = amounts.length;

        // Checks: count of `streamIds` matches count of `amounts`.
        if (streamIdsCount != amountsCount) {
            revert Errors.SablierV2Payroll_DepositArrayCountsNotEqual(streamIdsCount, amountsCount);
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

    /// @inheritdoc ISablierV2Payroll
    function refundFromStream(uint256 streamId, uint128 amount) external notCanceled(streamId) onlySender(streamId) {
        address sender = _streams[streamId].sender;
        uint128 senderAmount = refundableAmountOf(streamId);

        // Checks, Effects and Interactions: withdraw from the stream.
        _withdraw(streamId, sender, amount, senderAmount);

        // Log the refund.
        emit ISablierV2Payroll.RefundFromPayrollStream(streamId, sender, _streams[streamId].asset, amount);
    }

    /// @inheritdoc ISablierV2Payroll
    function withdraw(uint256 streamId, address to, uint128 amount) external {
        bool isCallerStreamSender = _isCallerStreamSender(streamId);
        address recipient = _streams[streamId].recipient;

        // Checks: `msg.sender` is the stream's sender or the stream's recipient.
        if (!isCallerStreamSender && !(msg.sender == recipient)) {
            revert Errors.SablierV2Payroll_Unauthorized(streamId, msg.sender);
        }

        // Checks: the provided address is the recipient if `msg.sender` is the sender of the stream.
        if (isCallerStreamSender && to != recipient) {
            revert Errors.SablierV2Payroll_Unauthorized(streamId, msg.sender);
        }

        // Checks: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierV2Payroll_WithdrawToZeroAddress();
        }

        uint128 recipientAmount = withdrawableAmountOf(streamId);

        // Effects: update the stream time.
        _streams[streamId].lastTimeUpdate = uint40(block.timestamp);

        // Effects and Interactions: withdraw from the stream.
        _withdraw(streamId, to, amount, recipientAmount);

        // Log the withdrawal.
        emit ISablierV2Payroll.WithdrawFromPayrollStream(streamId, to, _streams[streamId].asset, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `msg.sender` is the stream's sender.
    /// @param streamId The stream id for the query.
    function _isCallerStreamSender(uint256 streamId) internal view returns (bool) {
        return msg.sender == _streams[streamId].sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _adjustStream(uint256 streamId, uint128 newAmountPerSecond) internal {
        uint128 recipientAmount = withdrawableAmountOf(streamId);
        uint128 oldAmountPerSecond = _streams[streamId].amountPerSecond;

        // Effects: update the stream time.
        _streams[streamId].lastTimeUpdate = uint40(block.timestamp);

        // Effects: change the amount per second.
        _streams[streamId].amountPerSecond = newAmountPerSecond;

        if (recipientAmount > 0) {
            // Effects and interactions: update the `balance` and perform the ERC-20 transfer.
            _extractFromStream(streamId, _streams[streamId].recipient, recipientAmount);
        }

        // Log the adjustment.
        emit ISablierV2Payroll.AdjustPayrollStream(streamId, recipientAmount, oldAmountPerSecond, newAmountPerSecond);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _cancel(uint256 streamId) internal {
        address recipient = _streams[streamId].recipient;
        address sender = _streams[streamId].sender;

        uint128 senderAmount = refundableAmountOf(streamId);
        uint128 recipientAmount = withdrawableAmountOf(streamId);

        // Effects: mark the stream as canceled.
        _streams[streamId].wasCanceled = true;

        // Effects: set the amount per second to zero.
        _streams[streamId].amountPerSecond = 0;

        // Interactions: refund the sender, if any assets available.
        if (senderAmount > 0) {
            _extractFromStream(streamId, sender, senderAmount);
        }

        // Interactions: withdraw the assets to the recipient, if any.
        if (recipientAmount > 0) {
            _extractFromStream(streamId, sender, senderAmount);
        }

        // Log the cancellation.
        emit ISablierV2Payroll.CancelPayrollStream(
            streamId, sender, recipient, _streams[streamId].asset, senderAmount, recipientAmount
        );
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _create(
        address recipient,
        address sender,
        uint128 amountPerSecond,
        IERC20 asset
    )
        internal
        returns (uint256 streamId)
    {
        // Checks: the sender is not the zero address.
        if (sender == address(0)) {
            revert Errors.SablierV2Payroll_SenderZeroAddress();
        }

        // Checks: the recipient is not the zero address.
        if (recipient == address(0)) {
            revert Errors.SablierV2Payroll_RecipientZeroAddress();
        }

        // Checks: the amount per second is not zero.
        if (amountPerSecond == 0) {
            revert Errors.SablierV2Payroll_AmountPerSecondZero();
        }

        // Load the stream id.
        streamId = nextStreamId;

        // Effects: create the stream.
        _streams[streamId] = Payroll.Stream({
            amountPerSecond: amountPerSecond,
            asset: asset,
            balance: 0,
            isStream: true,
            lastTimeUpdate: uint40(block.timestamp),
            recipient: recipient,
            sender: sender,
            wasCanceled: false
        });

        // Effects: bump the next stream id and record the protocol fee.
        // Using unchecked arithmetic because these calculations cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Log the newly created stream.
        emit ISablierV2Payroll.CreatePayrollStream(
            streamId, sender, recipient, amountPerSecond, asset, uint40(block.timestamp)
        );
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _deposit(uint256 streamId, uint128 amount) internal notCanceled(streamId) {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2Payroll_DepositAmountZero();
        }

        // Effects: update the stream balance.
        _streams[streamId].balance += amount;

        // Retrieve the ERC-20 asset from storage.
        IERC20 asset = _streams[streamId].asset;

        // Interactions: transfer the deposit amount.
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // Log the deposit.
        emit ISablierV2Payroll.DepositPayrollStream(streamId, msg.sender, asset, amount);
    }

    /// @dev Helper function to update the `balance` and to perform the ERC-20 transfer.
    function _extractFromStream(uint256 streamId, address to, uint128 amount) internal {
        // Effects: update the stream balance.
        _streams[streamId].balance -= amount;

        // Interactions: perform the ERC-20 transfer.
        _streams[streamId].asset.safeTransfer(to, amount);
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _withdraw(
        uint256 streamId,
        address to,
        uint128 amount,
        uint128 availableAmount
    )
        internal
        notCanceled(streamId)
    {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2Payroll_AmountZero(streamId);
        }

        // Checks: the amount is not greater than what is available.
        if (amount > availableAmount) {
            revert Errors.SablierV2Payroll_Overdraw(streamId, amount, availableAmount);
        }

        // Effects and interactions: update the `balance` and perform the ERC-20 transfer.
        _extractFromStream(streamId, to, amount);
    }
}
