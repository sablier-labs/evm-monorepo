// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { UD60x18, toUD60x18 } from "@prb/math/UD60x18.sol";

import { DataTypes } from "./libraries/DataTypes.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { Helpers } from "./libraries/Helpers.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Linear } from "./interfaces/ISablierV2Linear.sol";
import { ISablierV2Recipient } from "./hooks/ISablierV2Recipient.sol";
import { ISablierV2Sender } from "./hooks/ISablierV2Sender.sol";
import { SablierV2 } from "./SablierV2.sol";

/// @title SablierV2Linear
/// @dev This contract implements the ISablierV2Linear interface.
contract SablierV2Linear is
    ISablierV2Linear, // one dependency
    SablierV2, // two dependencies
    ERC721("Sablier V2 Linear NFT", "SAB-V2-LIN") // six dependencies
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 linear streams mapped by unsigned integers.
    mapping(uint256 => DataTypes.LinearStream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(ISablierV2Comptroller initialComptroller, UD60x18 maxFee) SablierV2(initialComptroller, maxFee) {}

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Linear
    function getCliffTime(uint256 streamId) external view override returns (uint40 cliffTime) {
        cliffTime = _streams[streamId].cliffTime;
    }

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external view override returns (uint128 depositAmount) {
        depositAmount = _streams[streamId].depositAmount;
    }

    /// @inheritdoc ISablierV2
    function getRecipient(uint256 streamId) public view override(ISablierV2, SablierV2) returns (address recipient) {
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierV2
    function getReturnableAmount(uint256 streamId) external view returns (uint128 returnableAmount) {
        // If the stream does not exist, return zero.
        if (!_streams[streamId].isEntity) {
            return 0;
        }

        unchecked {
            uint128 withdrawableAmount = getWithdrawableAmount(streamId);
            returnableAmount =
                _streams[streamId].depositAmount -
                _streams[streamId].withdrawnAmount -
                withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) external view override returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external view override returns (uint40 startTime) {
        startTime = _streams[streamId].startTime;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external view override returns (uint40 stopTime) {
        stopTime = _streams[streamId].stopTime;
    }

    /// @inheritdoc ISablierV2Linear
    function getStream(uint256 streamId) external view override returns (DataTypes.LinearStream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2
    function getWithdrawableAmount(uint256 streamId) public view returns (uint128 withdrawableAmount) {
        // If the stream does not exist, return zero.
        if (!_streams[streamId].isEntity) {
            return 0;
        }

        // If the cliff time is greater than the block timestamp, return zero. Because the cliff time is
        // always greater than the start time, this also checks whether the start time is greater than
        // the block timestamp.
        uint256 currentTime = block.timestamp;
        uint256 cliffTime = uint256(_streams[streamId].cliffTime);
        if (cliffTime > currentTime) {
            return 0;
        }

        uint256 stopTime = uint256(_streams[streamId].stopTime);
        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= stopTime) {
                return _streams[streamId].depositAmount - _streams[streamId].withdrawnAmount;
            }

            // In all other cases, calculate how much the recipient can withdraw.
            uint256 startTime = uint256(_streams[streamId].startTime);
            UD60x18 elapsedTime = toUD60x18(currentTime - startTime);
            UD60x18 totalTime = toUD60x18(stopTime - startTime);
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            UD60x18 depositAmount = UD60x18.wrap(_streams[streamId].depositAmount);
            UD60x18 streamedAmount = elapsedTimePercentage.mul(depositAmount);
            withdrawableAmount = uint128(UD60x18.unwrap(streamedAmount)) - _streams[streamId].withdrawnAmount;
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].withdrawnAmount;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool result) {
        result = _streams[streamId].cancelable;
    }

    /// @inheritdoc ISablierV2
    function isEntity(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool result) {
        result = _streams[streamId].isEntity;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public view override streamExists(streamId) returns (string memory uri) {
        uri = "";
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Linear
    function createWithDuration(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        address operator,
        UD60x18 operatorFee,
        address token,
        bool cancelable,
        uint40 cliffDuration,
        uint40 totalDuration
    ) external returns (uint256 streamId) {
        // Calculate the cliff time and the stop time. It is fine to use unchecked arithmetic because the
        // `_createWithRange` function will nonetheless check that the stop time is greater than or equal to the
        // cliff time, and that the cliff time is greater than or equal to the start time.
        uint40 startTime = uint40(block.timestamp);
        uint40 cliffTime;
        uint40 stopTime;
        unchecked {
            cliffTime = startTime + cliffDuration;
            stopTime = startTime + totalDuration;
        }

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithRange(
            sender,
            recipient,
            grossDepositAmount,
            operator,
            operatorFee,
            token,
            cancelable,
            startTime,
            cliffTime,
            stopTime
        );
    }

    /// @inheritdoc ISablierV2Linear
    function createWithRange(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        address operator,
        UD60x18 operatorFee,
        address token,
        bool cancelable,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime
    ) external returns (uint256 streamId) {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithRange(
            sender,
            recipient,
            grossDepositAmount,
            operator,
            operatorFee,
            token,
            cancelable,
            startTime,
            cliffTime,
            stopTime
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierV2
    function _isApprovedOrOwner(
        uint256 streamId,
        address spender
    ) internal view override returns (bool isApprovedOrOwner) {
        address owner = _ownerOf(streamId);
        isApprovedOrOwner = (spender == owner || isApprovedForAll(owner, spender) || getApproved(streamId) == spender);
    }

    /// @inheritdoc SablierV2
    function _isCallerStreamSender(uint256 streamId) internal view override returns (bool result) {
        result = msg.sender == _streams[streamId].sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _burn(uint256 tokenId) internal override(ERC721, SablierV2) {
        ERC721._burn(tokenId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal override onlySenderOrRecipient(streamId) {
        DataTypes.LinearStream memory stream = _streams[streamId];

        // Calculate the withdraw and the return amounts.
        uint128 withdrawAmount = getWithdrawableAmount(streamId);
        uint128 returnAmount;
        unchecked {
            returnAmount = stream.depositAmount - stream.withdrawnAmount - withdrawAmount;
        }

        // Load the sender and the recipient in memory, we will need them below.
        address sender = _streams[streamId].sender;
        address recipient = getRecipient(streamId);

        // Effects: delete the stream from storage.
        delete _streams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (withdrawAmount > 0) {
            IERC20(stream.token).safeTransfer({ to: recipient, amount: withdrawAmount });
        }

        // Interactions: return the tokens to the sender, if any.
        if (returnAmount > 0) {
            IERC20(stream.token).safeTransfer({ to: sender, amount: returnAmount });
        }

        // Interactions: if the `msg.sender` is the sender and the recipient is a contract, try to invoke the cancel
        // hook on the recipient without reverting if the hook is not implemented, and without bubbling up any
        // potential revert.
        if (msg.sender == sender) {
            if (recipient.code.length > 0) {
                try
                    ISablierV2Recipient(recipient).onStreamCanceled({
                        streamId: streamId,
                        caller: msg.sender,
                        withdrawAmount: withdrawAmount,
                        returnAmount: returnAmount
                    })
                {} catch {}
            }
        }
        // Interactions: if the `msg.sender` is the recipient and the sender is a contract, try to invoke the cancel
        // hook on the sender without reverting if the hook is not implemented, and also without bubbling up any
        // potential revert.
        else {
            if (sender.code.length > 0) {
                try
                    ISablierV2Sender(sender).onStreamCanceled({
                        streamId: streamId,
                        caller: msg.sender,
                        withdrawAmount: withdrawAmount,
                        returnAmount: returnAmount
                    })
                {} catch {}
            }
        }

        // Emit an event.
        emit Events.Cancel(streamId, sender, recipient, withdrawAmount, returnAmount);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _createWithRange(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        address operator,
        UD60x18 operatorFee,
        address token,
        bool cancelable,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime
    ) internal returns (uint256 streamId) {
        // Checks: validate the streaming arguments.
        Helpers.checkCreateLinearArgs(grossDepositAmount, startTime, cliffTime, stopTime);

        // Safe Interactions: query the protocol fee associated with this token.
        // This interaction is safe because we are querying a Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(token);

        // Checks: check that the fees are not greater than `MAX_FEE`, and also calculate the fee amounts and the
        // deposit amount.
        (uint128 protocolFeeAmount, uint128 operatorFeeAmount, uint128 depositAmount) = Helpers.checkAndCalculateFees(
            grossDepositAmount,
            protocolFee,
            operatorFee,
            MAX_FEE
        );

        // Effects: record the protocol fee amount.
        // We're using unchecked arithmetic here because this calculation cannot realistically overflow, ever.
        unchecked {
            _protocolRevenues[token] += protocolFeeAmount;
        }

        // Effects: create the stream.
        streamId = nextStreamId;
        _streams[streamId] = DataTypes.LinearStream({
            cancelable: cancelable,
            cliffTime: cliffTime,
            depositAmount: depositAmount,
            isEntity: true,
            sender: sender,
            startTime: startTime,
            stopTime: stopTime,
            token: token,
            withdrawnAmount: 0
        });

        // Effects: bump the next stream id.
        // We're using unchecked arithmetic here because this calculation cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
        }

        // Effects: mint the NFT for the recipient by setting the stream id as the token id.
        _mint({ to: recipient, tokenId: streamId });

        // Interactions: perform the ERC-20 transfer to deposit the gross amount of tokens.
        IERC20(token).safeTransferFrom({ from: msg.sender, to: address(this), amount: grossDepositAmount });

        // Interactions: perform the ERC-20 transfer to pay the operator fee, if not zero.
        if (operatorFeeAmount > 0) {
            IERC20(token).safeTransfer({ to: operator, amount: operatorFeeAmount });
        }

        // Emit an event.
        emit Events.CreateLinearStream({
            streamId: streamId,
            funder: msg.sender,
            sender: sender,
            recipient: recipient,
            depositAmount: depositAmount,
            protocolFeeAmount: protocolFeeAmount,
            operator: operator,
            operatorFeeAmount: operatorFeeAmount,
            token: token,
            startTime: startTime,
            cliffTime: cliffTime,
            stopTime: stopTime,
            cancelable: cancelable
        });
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Effects: make the stream non-cancelable.
        _streams[streamId].cancelable = false;

        // Emit an event.
        emit Events.Renounce(streamId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal override {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2__WithdrawAmountZero(streamId);
        }

        // Checks: the amount is not greater than what can be withdrawn.
        uint128 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount({
                streamId: streamId,
                withdrawAmount: amount,
                withdrawableAmount: withdrawableAmount
            });
        }

        // Effects: update the withdrawn amount.
        unchecked {
            _streams[streamId].withdrawnAmount += amount;
        }

        // Load the stream and the recipient in memory, we will need it below.
        DataTypes.LinearStream memory stream = _streams[streamId];
        address recipient = getRecipient(streamId);

        // Effects: if the stream is done, delete the entity from the mapping.
        if (stream.depositAmount == stream.withdrawnAmount) {
            delete _streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        IERC20(stream.token).safeTransfer({ to: to, amount: amount });

        // Interactions: if the `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try
                ISablierV2Recipient(recipient).onStreamWithdrawn({
                    streamId: streamId,
                    caller: msg.sender,
                    withdrawAmount: amount
                })
            {} catch {}
        }

        // Emit an event.
        emit Events.Withdraw(streamId, to, amount);
    }
}
