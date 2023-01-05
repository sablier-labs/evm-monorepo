// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Amounts, Broker, CreateAmounts, Durations, LinearStream, Range } from "./types/Structs.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { Helpers } from "./libraries/Helpers.sol";

import { ISablierV2 } from "./interfaces/ISablierV2.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Linear } from "./interfaces/ISablierV2Linear.sol";
import { ISablierV2Recipient } from "./interfaces/hooks/ISablierV2Recipient.sol";
import { ISablierV2Sender } from "./interfaces/hooks/ISablierV2Sender.sol";
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
    mapping(uint256 => LinearStream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(ISablierV2Comptroller initialComptroller, UD60x18 maxFee) SablierV2(initialComptroller, maxFee) {}

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Linear
    function getCliffTime(uint256 streamId) external view override returns (uint40 cliffTime) {
        cliffTime = _streams[streamId].range.cliff;
    }

    /// @inheritdoc ISablierV2
    function getDepositAmount(uint256 streamId) external view override returns (uint128 depositAmount) {
        depositAmount = _streams[streamId].amounts.deposit;
    }

    /// @inheritdoc ISablierV2Linear
    function getRange(uint256 streamId) external view returns (Range memory range) {
        range = _streams[streamId].range;
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
                _streams[streamId].amounts.deposit -
                _streams[streamId].amounts.withdrawn -
                withdrawableAmount;
        }
    }

    /// @inheritdoc ISablierV2
    function getSender(uint256 streamId) external view override returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2
    function getStartTime(uint256 streamId) external view override returns (uint40 startTime) {
        startTime = _streams[streamId].range.start;
    }

    /// @inheritdoc ISablierV2
    function getStopTime(uint256 streamId) external view override returns (uint40 stopTime) {
        stopTime = _streams[streamId].range.stop;
    }

    /// @inheritdoc ISablierV2Linear
    function getStream(uint256 streamId) external view override returns (LinearStream memory stream) {
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
        uint256 cliffTime = uint256(_streams[streamId].range.cliff);
        if (cliffTime > currentTime) {
            return 0;
        }

        uint256 stopTime = uint256(_streams[streamId].range.stop);
        unchecked {
            // If the current time is greater than or equal to the stop time, return the deposit minus
            // the withdrawn amount.
            if (currentTime >= stopTime) {
                return _streams[streamId].amounts.deposit - _streams[streamId].amounts.withdrawn;
            }

            // In all other cases, calculate how much the recipient can withdraw.
            uint256 startTime = uint256(_streams[streamId].range.start);
            UD60x18 elapsedTime = ud(currentTime - startTime);
            UD60x18 totalTime = ud(stopTime - startTime);
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            UD60x18 depositAmount = ud(_streams[streamId].amounts.deposit);
            UD60x18 streamedAmount = elapsedTimePercentage.mul(depositAmount);
            withdrawableAmount = uint128(UD60x18.unwrap(streamedAmount)) - _streams[streamId].amounts.withdrawn;
        }
    }

    /// @inheritdoc ISablierV2
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2
    function isCancelable(uint256 streamId) public view override(ISablierV2, SablierV2) returns (bool result) {
        result = _streams[streamId].isCancelable;
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
    function createWithDurations(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        IERC20 token,
        bool cancelable,
        Durations calldata durations,
        Broker calldata broker
    ) external returns (uint256 streamId) {
        // Set the current block timestamp as the start time of the stream.
        Range memory range;
        range.start = uint40(block.timestamp);

        // Calculate the cliff time and the stop time. It is safe to use unchecked arithmetic because the
        // `_createWithRange` function will nonetheless check that the stop time is greater than or equal to the
        // cliff time, and also that the cliff time is greater than or equal to the start time.
        unchecked {
            range.cliff = range.start + durations.cliff;
            range.stop = range.start + durations.total;
        }

        // Safe Interactions: query the protocol fee. This is safe because we are querying a Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(token);

        // Checks: check the fees and calculate the fee amounts.
        CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            grossDepositAmount,
            protocolFee,
            broker.fee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithRange(
            CreateWithRangeParams({
                amounts: amounts,
                broker: broker.addr,
                cancelable: cancelable,
                recipient: recipient,
                sender: sender,
                range: range,
                token: token
            })
        );
    }

    /// @inheritdoc ISablierV2Linear
    function createWithRange(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        IERC20 token,
        bool cancelable,
        Range calldata range,
        Broker calldata broker
    ) external returns (uint256 streamId) {
        // Safe Interactions: query the protocol fee. This is safe because we are querying a Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(token);

        // Checks: check that neither fee is greater than `MAX_FEE`, and then calculate the fee amounts and the
        // deposit amount.
        CreateAmounts memory amounts = Helpers.checkAndCalculateFees(
            grossDepositAmount,
            protocolFee,
            broker.fee,
            MAX_FEE
        );

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithRange(
            CreateWithRangeParams({
                amounts: amounts,
                broker: broker.addr,
                cancelable: cancelable,
                recipient: recipient,
                sender: sender,
                range: range,
                token: token
            })
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
        LinearStream memory stream = _streams[streamId];

        // Calculate the withdraw and the return amounts.
        uint128 recipientAmount = getWithdrawableAmount(streamId);
        uint128 senderAmount;
        unchecked {
            senderAmount = stream.amounts.deposit - stream.amounts.withdrawn - recipientAmount;
        }

        // Load the sender and the recipient in memory, we will need them below.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Effects: delete the stream from storage.
        delete _streams[streamId];

        // Interactions: withdraw the tokens to the recipient, if any.
        if (recipientAmount > 0) {
            stream.token.safeTransfer({ to: recipient, amount: recipientAmount });
        }

        // Interactions: return the tokens to the sender, if any.
        if (senderAmount > 0) {
            stream.token.safeTransfer({ to: sender, amount: senderAmount });
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
                        recipientAmount: recipientAmount,
                        senderAmount: senderAmount
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
                        recipientAmount: recipientAmount,
                        senderAmount: senderAmount
                    })
                {} catch {}
            }
        }

        // Emit an event.
        emit Events.Cancel(streamId, sender, recipient, senderAmount, recipientAmount);
    }

    /// @dev This struct is needed to avoid the "Stack Too Deep" error.
    struct CreateWithRangeParams {
        CreateAmounts amounts;
        Range range;
        address sender; // ──┐
        bool cancelable; // ─┘
        address recipient;
        IERC20 token;
        address broker;
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _createWithRange(CreateWithRangeParams memory params) internal returns (uint256 streamId) {
        // Checks: validate the arguments.
        Helpers.checkCreateLinearParams(params.amounts.netDeposit, params.range);

        // Load the stream id.
        streamId = nextStreamId;

        // Effects: create the stream.
        _streams[streamId] = LinearStream({
            amounts: Amounts({ deposit: params.amounts.netDeposit, withdrawn: 0 }),
            isCancelable: params.cancelable,
            isEntity: true,
            sender: params.sender,
            range: params.range,
            token: params.token
        });

        // Effects: bump the next stream id and record the protocol fee.
        // We're using unchecked arithmetic here because theses calculations cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
            _protocolRevenues[params.token] += params.amounts.protocolFee;
        }

        // Effects: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        // Interactions: perform the ERC-20 transfer to deposit the gross amount of tokens.
        params.token.safeTransferFrom({ from: msg.sender, to: address(this), amount: params.amounts.netDeposit });

        // Interactions: perform the ERC-20 transfer to pay the broker fee, if not zero.
        if (params.amounts.brokerFee > 0) {
            params.token.safeTransferFrom({ from: msg.sender, to: params.broker, amount: params.amounts.brokerFee });
        }

        // Emit an event.
        emit Events.CreateLinearStream({
            streamId: streamId,
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: params.amounts,
            token: params.token,
            cancelable: params.cancelable,
            range: params.range,
            broker: params.broker
        });
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _renounce(uint256 streamId) internal override {
        // Effects: make the stream non-cancelable.
        _streams[streamId].isCancelable = false;

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
            revert Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount(streamId, amount, withdrawableAmount);
        }

        // Effects: update the withdrawn amount.
        unchecked {
            _streams[streamId].amounts.withdrawn += amount;
        }

        // Load the stream and the recipient in memory, we will need them below.
        LinearStream memory stream = _streams[streamId];
        address recipient = _ownerOf(streamId);

        // Assert that the withdrawn amount cannot get greater than the deposit amount.
        assert(stream.amounts.deposit >= stream.amounts.withdrawn);

        // Effects: if the entire deposit amount is now withdrawn, delete the stream entity.
        if (stream.amounts.deposit == stream.amounts.withdrawn) {
            delete _streams[streamId];
        }

        // Interactions: perform the ERC-20 transfer.
        stream.token.safeTransfer({ to: to, amount: amount });

        // Interactions: if the `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try
                ISablierV2Recipient(recipient).onStreamWithdrawn({
                    streamId: streamId,
                    caller: msg.sender,
                    amount: amount
                })
            {} catch {}
        }

        // Emit an event.
        emit Events.Withdraw(streamId, to, amount);
    }
}
