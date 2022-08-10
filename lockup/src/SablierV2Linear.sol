// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { UD60x18, toUD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "./interfaces/ISablierV2Linear.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Linear
/// @author Sablier Labs Ltd.
contract SablierV2Linear is
    ISablierV2Linear, // one dependency
    SablierV2 // one dependency
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 linear streams mapped by unsigned integers.
    mapping(uint256 => Stream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Linear
    function getCliffTime(uint256 streamId) external view override returns (uint256 cliffTime) {
        cliffTime = _streams[streamId].cliffTime;
    }

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external view override returns (uint256 depositAmount) {
        depositAmount = _streams[streamId].depositAmount;
    }

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public view override(ISablierV2, SablierV2) returns (address recipient) {
        recipient = _streams[streamId].recipient;
    }

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) external view returns (uint256 returnableAmount) {
        // If the stream does not exist, return zero.
        if (_streams[streamId].sender == address(0)) {
            return 0;
        }

        unchecked {
            uint256 withdrawableAmount = getWithdrawableAmount(streamId);
            returnableAmount =
                _streams[streamId].depositAmount -
                _streams[streamId].withdrawnAmount -
                withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) public view override(ISablierV2, SablierV2) returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external view override returns (uint256 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external view override returns (uint256 stopTime) {
        stopTime = _streams[streamId].stopTime;
    }

    /// @inheritdoc ISablierV2Linear
    function getStream(uint256 streamId) external view override returns (Stream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(uint256 streamId) public view returns (uint256 withdrawableAmount) {
        // If the stream does not exist, return zero.
        if (_streams[streamId].sender == address(0)) {
            return 0;
        }

        // If the cliff time is greater than the block timestamp, return zero. Because the cliff time is
        // always greater than the start time, this also checks whether the start time is greater than
        // the block timestamp.
        uint256 currentTime = block.timestamp;
        if (_streams[streamId].cliffTime > currentTime) {
            return 0;
        }

        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= _streams[streamId].stopTime) {
                return _streams[streamId].depositAmount - _streams[streamId].withdrawnAmount;
            }

            // In all other cases, calculate how much the recipient can withdraw.
            UD60x18 elapsedTime = toUD60x18(currentTime - _streams[streamId].startTime);
            UD60x18 totalTime = toUD60x18(_streams[streamId].stopTime - _streams[streamId].startTime);
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            UD60x18 depositAmount = UD60x18.wrap(_streams[streamId].depositAmount);
            UD60x18 streamedAmount = elapsedTimePercentage.mul(depositAmount);
            UD60x18 withdrawnAmount = UD60x18.wrap(_streams[streamId].withdrawnAmount);
            withdrawableAmount = UD60x18.unwrap(streamedAmount.uncheckedSub(withdrawnAmount));
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint256 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].withdrawnAmount;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool cancelable) {
        cancelable = _streams[streamId].cancelable;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Linear
    function create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, depositAmount, token, startTime, cliffTime, stopTime, cancelable);
    }

    /// @inheritdoc ISablierV2Linear
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 cliffDuration,
        uint256 totalDuration,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Calculate the cliff time and the stop time. It is fine to use unchecked arithmetic because the
        // `_create` function will nonetheless check that the stop time is greater than or equal to the
        // cliff time, and that the cliff time is greater than or equal to the start time.
        uint256 startTime = block.timestamp;
        uint256 cliffTime;
        uint256 stopTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
            stopTime = startTime + totalDuration;
        }

        // Checks, Effects and Interactions: create the stream.
        streamId = _create(sender, recipient, depositAmount, token, startTime, cliffTime, stopTime, cancelable);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal override onlySenderOrRecipient(streamId) {
        Stream memory stream = _streams[streamId];

        // Calculate the withdraw and the return amounts.
        uint256 withdrawAmount = getWithdrawableAmount(streamId);
        uint256 returnAmount;
        unchecked {
            returnAmount = stream.depositAmount - stream.withdrawnAmount - withdrawAmount;
        }

        // Effects: delete the stream from storage.
        delete _streams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (withdrawAmount > 0) {
            stream.token.safeTransfer(stream.recipient, withdrawAmount);
        }

        // Interactions: return the tokens to the sender, if any.
        if (returnAmount > 0) {
            stream.token.safeTransfer(stream.sender, returnAmount);
        }

        // Emit an event.
        emit Cancel(streamId, stream.recipient, withdrawAmount, returnAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    ) internal returns (uint256 streamId) {
        // Checks: the common requirements for the `create` function arguments.
        _checkCreateArguments(sender, recipient, depositAmount, startTime, stopTime);

        // Checks: the cliff time is greater than or equal to the start time.
        if (startTime > cliffTime) {
            revert SablierV2Linear__StartTimeGreaterThanCliffTime(startTime, cliffTime);
        }

        // Checks: the stop time is greater than or equal to the cliff time.
        if (cliffTime > stopTime) {
            revert SablierV2Linear__CliffTimeGreaterThanStopTime(cliffTime, stopTime);
        }

        // Effects: create and store the stream.
        streamId = nextStreamId;
        _streams[streamId] = Stream({
            cancelable: cancelable,
            cliffTime: cliffTime,
            depositAmount: depositAmount,
            recipient: recipient,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token,
            withdrawnAmount: 0
        });

        // Effects: bump the next stream id.
        // We're using unchecked arithmetic here because this cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Interactions: perform the ERC-20 transfer.
        token.safeTransferFrom(msg.sender, address(this), depositAmount);

        // Emit an event.
        emit CreateStream(
            streamId,
            msg.sender,
            sender,
            recipient,
            depositAmount,
            token,
            startTime,
            cliffTime,
            stopTime,
            cancelable
        );
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Effects: make the stream non-cancelable.
        _streams[streamId].cancelable = false;

        // Emit an event.
        emit Renounce(streamId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(
        uint256 streamId,
        address to,
        uint256 amount
    ) internal override {
        // Checks: the amount must not be zero.
        if (amount == 0) {
            revert SablierV2__WithdrawAmountZero(streamId);
        }

        // Checks: the amount must not be greater than what can be withdrawn.
        uint256 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            _streams[streamId].withdrawnAmount += amount;
        }

        // Load the stream in memory, we will need it below.
        Stream memory stream = _streams[streamId];

        // Effects: if this stream is done, save gas by deleting it from storage.
        if (stream.depositAmount == stream.withdrawnAmount) {
            delete _streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        stream.token.safeTransfer(to, amount);

        // Emit an event.
        emit Withdraw(streamId, to, amount);
    }
}
