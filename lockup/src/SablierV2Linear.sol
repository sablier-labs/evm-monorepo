// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.4;

import { console } from "forge-std/console.sol";

import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { PRBMathUD60x18 } from "@prb/math/PRBMathUD60x18.sol";
import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "./interfaces/ISablierV2Linear.sol";

/// @title SablierV2Linear
/// @author Sablier Labs Ltd.
contract SablierV2Linear is ISablierV2Linear {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    /// PUBLIC STORAGE ///

    /// @inheritdoc ISablierV2
    uint256 public override nextStreamId;

    /// INTERNAL STORAGE ///

    /// @dev Sablier V2 linear streams mapped by unsigned integers.
    mapping(uint256 => LinearStream) internal linearStreams;

    /// @dev Mapping from owners to creators to stream creation authorizations.
    mapping(address => mapping(address => uint256)) internal authorizations;

    /// MODIFIERS ///

    /// @dev Checks that `streamId` points to a stream that exists.
    modifier streamExists(uint256 streamId) {
        if (linearStreams[streamId].sender == address(0)) {
            revert SablierV2__StreamNonExistent(streamId);
        }
        _;
    }

    /// @notice Checks that `msg.sender` is either the sender or the recipient of the linear stream.
    modifier onlySenderOrRecipient(uint256 streamId) {
        if (msg.sender != linearStreams[streamId].sender && msg.sender != linearStreams[streamId].recipient) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }
        _;
    }

    /// CONSTRUCTOR ///

    constructor() {
        nextStreamId = 1;
    }

    /// CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2Linear
    function getLinearStream(uint256 streamId) external view override returns (LinearStream memory stream) {
        stream = linearStreams[streamId];
    }

    function getReturnableAmount(uint256 streamId) public view returns (uint256 returnableAmount) {
        // If the linear stream does not exist, return zero.
        LinearStream memory linearStream = linearStreams[streamId];
        if (linearStream.sender == address(0)) {
            return 0;
        }

        unchecked {
            uint256 withdrawableAmount = getWithdrawableAmount(streamId);
            returnableAmount = linearStream.depositAmount - linearStream.withdrawnAmount - withdrawableAmount;
        }
    }

    function getWithdrawableAmount(uint256 streamId) public view returns (uint256 withdrawableAmount) {
        // If the linear stream does not exist, return zero.
        LinearStream memory linearStream = linearStreams[streamId];
        if (linearStream.sender == address(0)) {
            return 0;
        }

        // If the start time is greater than or equal to the block timestamp, return zero.
        uint256 currentTime = block.timestamp;
        if (linearStream.startTime >= currentTime) {
            return 0;
        }

        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= linearStream.stopTime) {
                return linearStream.depositAmount - linearStream.withdrawnAmount;
            }

            // In all other cases, calculate how much the recipient can withdraw.
            uint256 elapsed = (currentTime - linearStream.startTime).fromUint();
            uint256 duration = (linearStream.stopTime - linearStream.startTime).fromUint();
            uint256 quotient = elapsed.div(duration);
            uint256 streamedAmount = quotient.mul(linearStream.depositAmount);
            withdrawableAmount = streamedAmount - linearStream.withdrawnAmount;
        }
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc ISablierV2
    function cancel(uint256 streamId) external streamExists(streamId) onlySenderOrRecipient(streamId) {
        LinearStream memory linearStream = linearStreams[streamId];

        // Checks: the linear stream is cancelable.
        if (!linearStream.cancelable) {
            revert SablierV2__StreamNonCancelable(streamId);
        }

        // Calculate the pay and the return amounts.
        uint256 withdrawAmount = getWithdrawableAmount(streamId);
        uint256 returnAmount;
        unchecked {
            returnAmount = linearStream.depositAmount - linearStream.withdrawnAmount - withdrawAmount;
        }

        // Effects: delete the linear stream from storage.
        delete linearStreams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (withdrawAmount > 0) {
            linearStream.token.safeTransfer(linearStream.recipient, withdrawAmount);
        }

        // Interactions: return the tokens to the sender, if any.
        if (returnAmount > 0) {
            linearStream.token.safeTransfer(linearStream.sender, returnAmount);
        }

        // Emit an event.
        emit Cancel(streamId, linearStream.recipient, withdrawAmount, returnAmount);
    }

    /// @inheritdoc ISablierV2Linear
    function create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId) {
        address from = msg.sender;
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);
    }

    /// @inheritdoc ISablierV2Linear
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
        bool cancelable
    ) external override returns (uint256 streamId) {
        address from = msg.sender;
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + duration;
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);
    }

    /// @inheritdoc ISablierV2Linear
    function createFrom(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
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

        // Effects & Interactions: create the linear stream.
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);

        // Effects: decrease the authorization since this stream has consumed part of it.
        unchecked {
            authorizeInternal(from, msg.sender, authorization - depositAmount);
        }
    }

    /// @inheritdoc ISablierV2Linear
    function createFromWithDuration(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
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

        // Effects & Interactions: create the linear stream.
        uint256 startTime = block.timestamp;
        uint256 stopTime = startTime + duration;
        streamId = createInternal(from, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);

        // Effects: decrease the authorization since this stream has consumed part of it.
        unchecked {
            authorizeInternal(from, msg.sender, authorization - depositAmount);
        }
    }

    /// @inheritdoc ISablierV2
    function decreaseAuthorization(address creator, uint256 amount) public override {
        uint256 newAuthorization = authorizations[msg.sender][creator] - amount;
        authorizeInternal(msg.sender, creator, newAuthorization);
    }

    /// @inheritdoc ISablierV2
    function increaseAuthorization(address creator, uint256 amount) public override {
        uint256 newAuthorization = authorizations[msg.sender][creator] + amount;
        authorizeInternal(msg.sender, creator, newAuthorization);
    }

    /// @inheritdoc ISablierV2
    function renounce(uint256 streamId) external streamExists(streamId) {
        LinearStream memory linearStream = linearStreams[streamId];

        // Checks: the caller is the sender of the linear stream.
        if (msg.sender != linearStreams[streamId].sender) {
            revert SablierV2__Unauthorized(streamId, msg.sender);
        }

        // Checks: the linear stream is not already non-cancelable.
        if (!linearStream.cancelable) {
            revert SablierV2__RenounceNonCancelableStream(streamId);
        }

        // Effects: make the stream non-cancelable.
        linearStreams[streamId].cancelable = false;

        // Emit an event.
        emit Renounce(streamId);
    }

    /// @inheritdoc ISablierV2
    function withdraw(uint256 streamId, uint256 amount)
        external
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
    {
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
            linearStreams[streamId].withdrawnAmount += amount;
        }

        // Load the linear stream in memory, we will need it later.
        LinearStream memory linearStream = linearStreams[streamId];

        // Effects: if this linear stream is done, save gas by deleting it from storage.
        if (linearStreams[streamId].depositAmount == linearStreams[streamId].withdrawnAmount) {
            delete linearStreams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        linearStream.token.safeTransfer(linearStream.recipient, amount);

        // Emit an event.
        emit Withdraw(streamId, linearStream.recipient, amount);
    }

    /// INTERNAL FUNCTIONS ///

    /// @dev See the documentation for the public functions that call this internal function.
    function authorizeInternal(
        address owner,
        address creator,
        uint256 amount
    ) internal virtual {
        // Checks: the owner is not the zero address.
        if (owner == address(0)) {
            revert SablierV2__OwnerZeroAddress();
        }

        // Checks: the creator is not the zero address.
        if (creator == address(0)) {
            revert SablierV2__CreatorZeroAddress();
        }

        // Effects: update the authorization for the given owner and creator pair.
        authorizations[owner][creator] = amount;

        // Emit an event.
        emit Authorize(owner, creator, amount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function createInternal(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
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

        // Effects: create and store the linear stream.
        streamId = nextStreamId;
        linearStreams[streamId] = LinearStream({
            cancelable: cancelable,
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
        emit CreateLinearStream(streamId, sender, recipient, depositAmount, token, startTime, stopTime, cancelable);
    }
}
