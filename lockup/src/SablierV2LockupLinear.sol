// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20 } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { Status } from "./types/Enums.sol";
import { LockupAmounts, Broker, LockupCreateAmounts, Durations, LockupLinearStream, Range } from "./types/Structs.sol";

import { SablierV2Lockup } from "./abstracts/SablierV2Lockup.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2Lockup } from "./interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupLinear } from "./interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2LockupRecipient } from "./interfaces/hooks/ISablierV2LockupRecipient.sol";
import { ISablierV2LockupSender } from "./interfaces/hooks/ISablierV2LockupSender.sol";

/// @title SablierV2LockupLinear
/// @dev This contract implements the {ISablierV2LockupLinear} interface.
contract SablierV2LockupLinear is
    ISablierV2LockupLinear, // one dependency
    ERC721("SablierV2LockupLinear NFT", "SAB-V2-LOCKUP-LIN"), // six dependencies
    SablierV2Lockup // ten dependencies
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Sablier V2 linear lockup streams mapped by unsigned integers.
    mapping(uint256 => LockupLinearStream) internal _streams;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param maxFee The maximum fee that can be charged by either the protocol or a broker, as an UD60x18 number
    /// where 100% = 1e18.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        UD60x18 maxFee
    ) SablierV2Lockup(initialAdmin, initialComptroller, maxFee) {}

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Lockup
    function getAsset(uint256 streamId) external view override returns (IERC20 asset) {
        asset = _streams[streamId].asset;
    }

    /// @inheritdoc ISablierV2LockupLinear
    function getCliffTime(uint256 streamId) external view override returns (uint40 cliffTime) {
        cliffTime = _streams[streamId].range.cliff;
    }

    /// @inheritdoc ISablierV2Lockup
    function getDepositAmount(uint256 streamId) external view override returns (uint128 depositAmount) {
        depositAmount = _streams[streamId].amounts.deposit;
    }

    /// @inheritdoc ISablierV2LockupLinear
    function getRange(uint256 streamId) external view override returns (Range memory range) {
        range = _streams[streamId].range;
    }

    /// @inheritdoc ISablierV2Lockup
    function getRecipient(
        uint256 streamId
    ) public view override(ISablierV2Lockup, SablierV2Lockup) returns (address recipient) {
        recipient = _ownerOf(streamId);
    }

    /// @inheritdoc ISablierV2Lockup
    function getReturnableAmount(uint256 streamId) external view returns (uint128 returnableAmount) {
        // If the stream is null, return zero.
        if (_streams[streamId].status == Status.NULL) {
            return 0;
        }

        // No need for an assertion here, since the {getStreamedAmount} function checks that the deposit amount
        // is greater than or equal to the streamed amount.
        unchecked {
            returnableAmount = _streams[streamId].amounts.deposit - getStreamedAmount(streamId);
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function getSender(uint256 streamId) external view override returns (address sender) {
        sender = _streams[streamId].sender;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStartTime(uint256 streamId) external view override returns (uint40 startTime) {
        startTime = _streams[streamId].range.start;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStatus(
        uint256 streamId
    ) public view virtual override(ISablierV2Lockup, SablierV2Lockup) returns (Status status) {
        status = _streams[streamId].status;
    }

    /// @inheritdoc ISablierV2Lockup
    function getStopTime(uint256 streamId) external view override returns (uint40 stopTime) {
        stopTime = _streams[streamId].range.stop;
    }

    /// @inheritdoc ISablierV2LockupLinear
    function getStream(uint256 streamId) external view override returns (LockupLinearStream memory stream) {
        stream = _streams[streamId];
    }

    /// @inheritdoc ISablierV2Lockup
    function getStreamedAmount(uint256 streamId) public view override returns (uint128 streamedAmount) {
        // If the stream is null, return zero.
        if (_streams[streamId].status == Status.NULL) {
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

        // If the current time is greater than or equal to the stop time, we simply return the deposit minus
        // the withdrawn amount.
        if (currentTime >= stopTime) {
            return _streams[streamId].amounts.deposit;
        }

        unchecked {
            // In all other cases, calculate how much was streamed so far.
            // First, calculate how much time has elapsed since the stream started, and the total time of the stream.
            uint256 startTime = uint256(_streams[streamId].range.start);
            UD60x18 elapsedTime = ud(currentTime - startTime);
            UD60x18 totalTime = ud(stopTime - startTime);

            // Then, calculate the streamed amount.
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            UD60x18 depositAmount = ud(_streams[streamId].amounts.deposit);
            UD60x18 streamedAmountUd = elapsedTimePercentage.mul(depositAmount);

            // Assert that the streamed amount is lower than or equal to the deposit amount.
            assert(streamedAmountUd.lte(depositAmount));

            // Casting to uint128 is safe thanks to the assertion above.
            streamedAmount = uint128(streamedAmountUd.intoUint256());
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function getWithdrawableAmount(
        uint256 streamId
    ) public view override(ISablierV2Lockup, SablierV2Lockup) returns (uint128 withdrawableAmount) {
        unchecked {
            withdrawableAmount = getStreamedAmount(streamId) - _streams[streamId].amounts.withdrawn;
        }
    }

    /// @inheritdoc ISablierV2Lockup
    function getWithdrawnAmount(uint256 streamId) external view override returns (uint128 withdrawnAmount) {
        withdrawnAmount = _streams[streamId].amounts.withdrawn;
    }

    /// @inheritdoc ISablierV2Lockup
    function isCancelable(
        uint256 streamId
    ) public view override(ISablierV2Lockup, SablierV2Lockup) returns (bool result) {
        if (_streams[streamId].status != Status.ACTIVE) {
            return false;
        }
        result = _streams[streamId].isCancelable;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 streamId) public pure override(IERC721Metadata, ERC721) returns (string memory uri) {
        streamId;
        uri = "";
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupLinear
    function createWithDurations(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        IERC20 asset,
        bool cancelable,
        Durations calldata durations,
        Broker calldata broker
    ) external returns (uint256 streamId) {
        // Set the current block timestamp as the start time of the stream.
        Range memory range;
        range.start = uint40(block.timestamp);

        // Calculate the cliff time and the stop time. It is safe to use unchecked arithmetic because the
        // {_createWithRange} function will nonetheless check that the stop time is greater than or equal to the
        // cliff time, and also that the cliff time is greater than or equal to the start time.
        unchecked {
            range.cliff = range.start + durations.cliff;
            range.stop = range.start + durations.total;
        }

        // Safe Interactions: query the protocol fee. This is safe because it's a known Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(asset);

        // Checks: check the fees and calculate the fee amounts.
        LockupCreateAmounts memory amounts = Helpers.checkAndCalculateFees(
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
                asset: asset
            })
        );
    }

    /// @inheritdoc ISablierV2LockupLinear
    function createWithRange(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        IERC20 asset,
        bool cancelable,
        Range calldata range,
        Broker calldata broker
    ) external returns (uint256 streamId) {
        // Safe Interactions: query the protocol fee. This is safe because it's a known Sablier contract.
        UD60x18 protocolFee = comptroller.getProtocolFee(asset);

        // Checks: check that neither fee is greater than `MAX_FEE`, and then calculate the fee amounts and the
        // deposit amount.
        LockupCreateAmounts memory amounts = Helpers.checkAndCalculateFees(
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
                asset: asset
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierV2Lockup
    function _isApprovedOrOwner(
        uint256 streamId,
        address spender
    ) internal view override returns (bool isApprovedOrOwner) {
        address owner = _ownerOf(streamId);
        isApprovedOrOwner = (spender == owner || isApprovedForAll(owner, spender) || getApproved(streamId) == spender);
    }

    /// @inheritdoc SablierV2Lockup
    function _isCallerStreamSender(uint256 streamId) internal view override returns (bool result) {
        result = msg.sender == _streams[streamId].sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the public functions that call this internal function.
    function _burn(uint256 tokenId) internal override(ERC721, SablierV2Lockup) {
        ERC721._burn(tokenId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _cancel(uint256 streamId) internal override onlySenderOrRecipient(streamId) {
        LockupLinearStream memory stream = _streams[streamId];

        // Calculate the recipient's and the sender's amount.
        uint128 recipientAmount = getWithdrawableAmount(streamId);
        uint128 senderAmount;
        unchecked {
            senderAmount = stream.amounts.deposit - stream.amounts.withdrawn - recipientAmount;
        }

        // Load the sender and the recipient in memory, they will be needed below.
        address sender = _streams[streamId].sender;
        address recipient = _ownerOf(streamId);

        // Effects: mark the stream as canceled.
        _streams[streamId].status = Status.CANCELED;

        if (recipientAmount > 0) {
            // Effects: add the recipient's amount to the withdrawn amount.
            unchecked {
                _streams[streamId].amounts.withdrawn += recipientAmount;
            }

            // Interactions: withdraw the tokens to the recipient.
            stream.asset.safeTransfer({ to: recipient, amount: recipientAmount });
        }

        // Interactions: return the assets to the sender, if any.
        if (senderAmount > 0) {
            stream.asset.safeTransfer({ to: sender, amount: senderAmount });
        }

        // Interactions: if the `msg.sender` is the sender and the recipient is a contract, try to invoke the cancel
        // hook on the recipient without reverting if the hook is not implemented, and without bubbling up any
        // potential revert.
        if (msg.sender == sender) {
            if (recipient.code.length > 0) {
                try
                    ISablierV2LockupRecipient(recipient).onStreamCanceled({
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
                    ISablierV2LockupSender(sender).onStreamCanceled({
                        streamId: streamId,
                        caller: msg.sender,
                        recipientAmount: recipientAmount,
                        senderAmount: senderAmount
                    })
                {} catch {}
            }
        }

        // Emit an event.
        emit Events.CancelLockupStream(streamId, sender, recipient, senderAmount, recipientAmount);
    }

    /// @dev This struct is needed to avoid the "Stack Too Deep" error.
    struct CreateWithRangeParams {
        LockupCreateAmounts amounts;
        Range range;
        address sender; // ──┐
        bool cancelable; // ─┘
        address recipient;
        IERC20 asset;
        address broker;
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _createWithRange(CreateWithRangeParams memory params) internal returns (uint256 streamId) {
        // Checks: validate the arguments.
        Helpers.checkCreateLinearParams(params.amounts.netDeposit, params.range);

        // Load the stream id.
        streamId = nextStreamId;

        // Effects: create the stream.
        _streams[streamId] = LockupLinearStream({
            amounts: LockupAmounts({ deposit: params.amounts.netDeposit, withdrawn: 0 }),
            isCancelable: params.cancelable,
            sender: params.sender,
            status: Status.ACTIVE,
            range: params.range,
            asset: params.asset
        });

        // Effects: bump the next stream id and record the protocol fee.
        // Using unchecked arithmetic because these calculations cannot realistically overflow, ever.
        unchecked {
            nextStreamId = streamId + 1;
            _protocolRevenues[params.asset] += params.amounts.protocolFee;
        }

        // Effects: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        // Interactions: perform the ERC-20 transfer to deposit the net amount of assets, and also the protocol fee.
        // Using unchecked arithmetic because the net deposit and the protocol fee are bounded by the gross deposit.
        unchecked {
            params.asset.safeTransferFrom({
                from: msg.sender,
                to: address(this),
                amount: params.amounts.netDeposit + params.amounts.protocolFee
            });
        }

        // Interactions: perform the ERC-20 transfer to pay the broker fee, if not zero.
        if (params.amounts.brokerFee > 0) {
            params.asset.safeTransferFrom({ from: msg.sender, to: params.broker, amount: params.amounts.brokerFee });
        }

        // Emit an event.
        emit Events.CreateLockupLinearStream({
            streamId: streamId,
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: params.amounts,
            asset: params.asset,
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
        emit Events.RenounceLockupStream(streamId);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function _withdraw(uint256 streamId, address to, uint128 amount) internal override {
        // Checks: the amount is not zero.
        if (amount == 0) {
            revert Errors.SablierV2Lockup_WithdrawAmountZero(streamId);
        }

        // Checks: the amount is not greater than what can be withdrawn.
        uint128 withdrawableAmount = getWithdrawableAmount(streamId);
        if (amount > withdrawableAmount) {
            revert Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount(
                streamId,
                amount,
                withdrawableAmount
            );
        }

        // Effects: update the withdrawn amount.
        unchecked {
            _streams[streamId].amounts.withdrawn += amount;
        }

        // Load the stream and the recipient in memory, they will be needed below.
        LockupLinearStream memory stream = _streams[streamId];
        address recipient = _ownerOf(streamId);

        // Assert that the withdrawn amount is greater than or equal to the deposit amount.
        assert(stream.amounts.deposit >= stream.amounts.withdrawn);

        // Effects: if the entire deposit amount is now withdrawn, mark the stream as depleted.
        if (stream.amounts.deposit == stream.amounts.withdrawn) {
            _streams[streamId].status = Status.DEPLETED;
        }

        // Interactions: perform the ERC-20 transfer.
        stream.asset.safeTransfer({ to: to, amount: amount });

        // Interactions: if the `msg.sender` is not the recipient and the recipient is a contract, try to invoke the
        // withdraw hook on it without reverting if the hook is not implemented, and also without bubbling up
        // any potential revert.
        if (msg.sender != recipient && recipient.code.length > 0) {
            try
                ISablierV2LockupRecipient(recipient).onStreamWithdrawn({
                    streamId: streamId,
                    caller: msg.sender,
                    amount: amount
                })
            {} catch {}
        }

        // Emit an event.
        emit Events.WithdrawFromLockupStream(streamId, to, amount);
    }
}
