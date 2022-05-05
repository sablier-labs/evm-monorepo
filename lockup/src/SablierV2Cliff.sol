// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.4;

import { console } from "forge-std/console.sol";

import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { PRBMathUD60x18 } from "@prb/math/PRBMathUD60x18.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Cliff } from "./interfaces/ISablierV2Cliff.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Cliff
/// @author Sablier Labs Ltd.
contract SablierV2Cliff is
    ISablierV2Cliff, // one dependency
    SablierV2 // one dependency
{
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    /// PUBLIC STORAGE ///

    /// INTERNAL STORAGE ///

    /// @dev Sablier V2 cliff streams mapped by unsigned integers.
    mapping(uint256 => Stream) internal streams;

    /// MODIFIERS ///

    /// @dev Checks that `streamId` points to a stream that exists.
    modifier streamExists(uint256 streamId) {
        if (streams[streamId].sender == address(0)) {
            revert SablierV2__StreamNonExistent(streamId);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is either the sender or the recipient of the stream.
    modifier onlySenderOrRecipient(uint256 streamId) {
        if (msg.sender != streams[streamId].sender && msg.sender != streams[streamId].recipient) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// CONSTRUCTOR ///

    constructor() {
        nextStreamId = 1;
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) public view returns (uint256 returnableAmount) {
        // If the stream does not exist, return zero.
        Stream memory stream = streams[streamId];
        if (stream.sender == address(0)) {
            return 0;
        }

        unchecked {
            uint256 withdrawableAmount = getWithdrawableAmount(streamId);
            returnableAmount = stream.depositAmount - stream.withdrawnAmount - withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2Cliff
    function getStream(uint256 streamId) external view override returns (Stream memory stream) {
        stream = streams[streamId];
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(uint256 streamId) public view returns (uint256 withdrawableAmount) {
        // If the stream does not exist, return zero.
        Stream memory stream = streams[streamId];
        if (stream.sender == address(0)) {
            return 0;
        }

        // If the cliff time is greater than the block timestamp, return zero.
        uint256 currentTime = block.timestamp;
        if (stream.cliffTime > currentTime) {
            return 0;
        }

        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= stream.stopTime) {
                return stream.depositAmount - stream.withdrawnAmount;
            }

            // In all other cases, calculate how much the recipient can withdraw.
            uint256 elapsed = (currentTime - stream.startTime).fromUint();
            uint256 duration = (stream.stopTime - stream.startTime).fromUint();
            uint256 quotient = elapsed.div(duration);
            uint256 streamedAmount = quotient.mul(stream.depositAmount);
            withdrawableAmount = streamedAmount - stream.withdrawnAmount;
        }
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function cancel(uint256 streamId) external streamExists(streamId) onlySenderOrRecipient(streamId) {
        Stream memory stream = streams[streamId];

        // Checks: the stream is cancelable.
        if (!stream.cancelable) {
            revert SablierV2__StreamNonCancelable(streamId);
        }

        // Calculate the pay and the return amounts.
        uint256 withdrawAmount = getWithdrawableAmount(streamId);
        uint256 returnAmount;
        unchecked {
            returnAmount = stream.depositAmount - stream.withdrawnAmount - withdrawAmount;
        }

        // Effects: delete the stream from storage.
        delete streams[streamId];

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

    /// @inheritdoc ISablierV2Cliff
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
        address from = msg.sender;
        streamId = createInternal(
            from,
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

    /// @inheritdoc ISablierV2Cliff
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 cliffDuration,
        uint256 totalDuration,
        bool cancelable
    ) external override returns (uint256 streamId) {
        address from = msg.sender;
        uint256 startTime = block.timestamp;
        uint256 cliffTime = startTime + cliffDuration;
        uint256 stopTime = startTime + totalDuration;
        streamId = createInternal(
            from,
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

    /// @inheritdoc ISablierV2Cliff
    function createFrom(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Checks: the funder is not the zero address.
        if (from == address(0)) {
            revert SablierV2__FromZeroAddress();
        }

        // Checks: the caller has sufficient authorization to create this stream on behalf of `from`.
        uint256 authorization = authorizations[from][msg.sender];
        if (authorization < depositAmount) {
            revert SablierV2__InsufficientAuthorization(from, msg.sender, authorization, depositAmount);
        }

        // Effects & Interactions: create the stream.
        streamId = createInternal(
            from,
            sender,
            recipient,
            depositAmount,
            token,
            startTime,
            cliffTime,
            stopTime,
            cancelable
        );

        // Effects: decrease the authorization since this stream has consumed part of it.
        unchecked {
            authorizeInternal(from, msg.sender, authorization - depositAmount);
        }
    }

    /// @inheritdoc ISablierV2Cliff
    function createFromWithDuration(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 cliffDuration,
        uint256 totalDuration,
        bool cancelable
    ) external returns (uint256 streamId) {
        // Checks: the funder is not the zero address.
        if (from == address(0)) {
            revert SablierV2__FromZeroAddress();
        }

        // Checks: `msg.sender` has sufficient authorization to create this stream on behalf of `from`.
        uint256 authorization = authorizations[from][msg.sender];
        if (authorization < depositAmount) {
            revert SablierV2__InsufficientAuthorization(from, msg.sender, authorization, depositAmount);
        }

        // Effects & Interactions: create the stream.
        uint256 startTime = block.timestamp;
        uint256 cliffTime = startTime + cliffDuration;
        uint256 stopTime = startTime + totalDuration;
        streamId = createInternal(
            from,
            sender,
            recipient,
            depositAmount,
            token,
            startTime,
            cliffTime,
            stopTime,
            cancelable
        );

        // Effects: decrease the authorization since this stream has consumed part of it.
        unchecked {
            authorizeInternal(from, msg.sender, authorization - depositAmount);
        }
    }

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external streamExists(streamId) {
        Stream memory stream = streams[streamId];

        // Checks: the caller is the sender of the stream.
        if (msg.sender != streams[streamId].sender) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the stream is not already non-cancelable.
        if (!stream.cancelable) {
            revert SablierV2__RenounceNonCancelableStream(streamId);
        }

        // Effects: make the stream non-cancelable.
        streams[streamId].cancelable = false;

        // Emit an event.
        emit Renounce(streamId);
    }

    /// @inheritdoc ISablierV2
    function withdraw(uint256 streamId, uint256 amount)
        external
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
    {
        Stream memory stream = streams[streamId];
        // Checks: the amount cannot be zero.
        if (amount == 0) {
            revert SablierV2__WithdrawAmountZero(streamId);
        }

        // Checks: the amount cannot be greater than what can be withdrawn.
        uint256 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            streams[streamId].withdrawnAmount += amount;
        }

        // Load the stream in memory, we will need it later.
        // Stream memory stream = streams[streamId];

        // Effects: if this stream is done, save gas by deleting it from storage.
        if (streams[streamId].depositAmount == streams[streamId].withdrawnAmount) {
            delete streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        stream.token.safeTransfer(stream.recipient, amount);

        // Emit an event.
        emit Withdraw(streamId, stream.recipient, amount);
    }

    /// INTERNAL FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function createInternal(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    ) internal returns (uint256 streamId) {
        // Checks: the sender is not the zero address.
        if (sender == address(0)) {
            revert SablierV2__SenderZeroAddress();
        }

        // Checks: the recipient is not the zero address.
        if (recipient == address(0)) {
            revert SablierV2__RecipientZeroAddress();
        }

        // Checks: the deposit amount is not zero.
        if (depositAmount == 0) {
            revert SablierV2__DepositAmountZero();
        }

        // Checks: the start time is not greater than the stop time.
        if (startTime > stopTime) {
            revert SablierV2__StartTimeGreaterThanStopTime(startTime, stopTime);
        }

        // Checks: the start time is not greater than the cliff time.
        if (startTime > cliffTime) {
            revert SablierV2Cliff__StartTimeGreaterThanCliffTime(startTime, cliffTime);
        }

        // Checks: the cliff time is not greater than the stop time.
        if (cliffTime > stopTime) {
            revert SablierV2Cliff__CliffTimeGreaterThanStopTime(cliffTime, stopTime);
        }

        // Effects: create and store the stream.
        streamId = nextStreamId;
        streams[streamId] = Stream({
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
        token.safeTransferFrom(from, address(this), depositAmount);

        // Emit an event.
        emit CreateStream(
            streamId,
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
}
