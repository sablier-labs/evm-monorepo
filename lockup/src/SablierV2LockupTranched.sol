// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { SablierV2Lockup } from "./abstracts/SablierV2Lockup.sol";
import { ISablierV2Comptroller } from "./interfaces/ISablierV2Comptroller.sol";
import { ISablierV2LockupTranched } from "./interfaces/ISablierV2LockupTranched.sol";
import { ISablierV2NFTDescriptor } from "./interfaces/ISablierV2NFTDescriptor.sol";
import { Helpers } from "./libraries/Helpers.sol";
import { Lockup, LockupTranched } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗     ██╗   ██╗██████╗     
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗    ██║   ██║╚════██╗    
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝    ██║   ██║ █████╔╝    
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗    ╚██╗ ██╔╝██╔═══╝     
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║     ╚████╔╝ ███████╗    
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝      ╚═══╝  ╚══════╝    

██╗      ██████╗  ██████╗██╗  ██╗██╗   ██╗██████╗    ████████╗██████╗  █████╗ ███╗   ██╗ ██████╗██╗  ██╗███████╗██████╗ 
██║     ██╔═══██╗██╔════╝██║ ██╔╝██║   ██║██╔══██╗   ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██║  ██║██╔════╝██╔══██╗
██║     ██║   ██║██║     █████╔╝ ██║   ██║██████╔╝      ██║   ██████╔╝███████║██╔██╗ ██║██║     ███████║█████╗  ██║  ██║
██║     ██║   ██║██║     ██╔═██╗ ██║   ██║██╔═══╝       ██║   ██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══██║██╔══╝  ██║  ██║
███████╗╚██████╔╝╚██████╗██║  ██╗╚██████╔╝██║           ██║   ██║  ██║██║  ██║██║ ╚████║╚██████╗██║  ██║███████╗██████╔╝
╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝           ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝ 

*/

/// @title SablierV2LockupTranched
/// @notice See the documentation in {ISablierV2LockupTranched}.
contract SablierV2LockupTranched is
    ISablierV2LockupTranched, // 6 inherited components
    SablierV2Lockup // 14 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupTranched
    uint256 public immutable override MAX_TRANCHE_COUNT;

    /// @dev Stream tranches mapped by stream ids.
    mapping(uint256 id => LockupTranched.Tranche[] tranches) internal _tranches;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialComptroller The address of the initial comptroller.
    /// @param initialNFTDescriptor The address of the NFT descriptor contract.
    /// @param maxTrancheCount The maximum number of tranches allowed in a stream.
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller,
        ISablierV2NFTDescriptor initialNFTDescriptor,
        uint256 maxTrancheCount
    )
        ERC721("Sablier V2 Lockup Tranched NFT", "SAB-V2-LOCKUP-TRA")
        SablierV2Lockup(initialAdmin, initialComptroller, initialNFTDescriptor)
    {
        MAX_TRANCHE_COUNT = maxTrancheCount;
        nextStreamId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupTranched
    function getRange(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupTranched.Range memory range)
    {
        range = LockupTranched.Range({ start: _streams[streamId].startTime, end: _streams[streamId].endTime });
    }

    /// @inheritdoc ISablierV2LockupTranched
    function getStream(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupTranched.StreamLT memory stream)
    {
        // Retrieve the lockup stream from storage.
        Lockup.Stream memory lockupStream = _streams[streamId];

        // Settled streams cannot be canceled.
        if (_statusOf(streamId) == Lockup.Status.SETTLED) {
            lockupStream.isCancelable = false;
        }

        stream = LockupTranched.StreamLT({
            amounts: lockupStream.amounts,
            asset: lockupStream.asset,
            endTime: lockupStream.endTime,
            isCancelable: lockupStream.isCancelable,
            isTransferable: lockupStream.isTransferable,
            isDepleted: lockupStream.isDepleted,
            isStream: lockupStream.isStream,
            sender: lockupStream.sender,
            startTime: lockupStream.startTime,
            tranches: _tranches[streamId],
            wasCanceled: lockupStream.wasCanceled
        });
    }

    /// @inheritdoc ISablierV2LockupTranched
    function getTranches(uint256 streamId)
        external
        view
        override
        notNull(streamId)
        returns (LockupTranched.Tranche[] memory tranches)
    {
        tranches = _tranches[streamId];
    }

    /// @inheritdoc ISablierV2LockupTranched
    function streamedAmountOf(uint256 streamId)
        public
        view
        override(SablierV2Lockup, ISablierV2LockupTranched)
        returns (uint128)
    {
        return super.streamedAmountOf(streamId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2LockupTranched
    function createWithDurations(LockupTranched.CreateWithDurations calldata params)
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks: check the durations and generate the canonical tranches.
        LockupTranched.Tranche[] memory tranches = Helpers.checkDurationsAndCalculateTimestamps(params.tranches);

        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithTimestamps(
            LockupTranched.CreateWithTimestamps({
                sender: params.sender,
                recipient: params.recipient,
                totalAmount: params.totalAmount,
                asset: params.asset,
                cancelable: params.cancelable,
                transferable: params.transferable,
                startTime: uint40(block.timestamp),
                tranches: tranches,
                broker: params.broker
            })
        );
    }

    /// @inheritdoc ISablierV2LockupTranched
    function createWithTimestamps(LockupTranched.CreateWithTimestamps calldata params)
        external
        override
        noDelegateCall
        returns (uint256 streamId)
    {
        // Checks, Effects and Interactions: create the stream.
        streamId = _createWithTimestamps(params);
    }

    /*//////////////////////////////////////////////////////////////////////////
                             INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierV2Lockup
    function _calculateStreamedAmount(uint256 streamId) internal view override returns (uint128) {
        uint40 currentTime = uint40(block.timestamp);

        LockupTranched.Tranche[] memory tranches = _tranches[streamId];

        // If the first timestamp in the tranches is in the future, return zero.
        if (tranches[0].timestamp > currentTime) {
            return 0;
        }

        // If the end time is not in the future, return the deposited amount.
        if (_streams[streamId].endTime <= currentTime) {
            return _streams[streamId].amounts.deposited;
        }

        // Sum the amounts in all tranches that precede the current time.
        uint128 streamedAmount = tranches[0].amount;
        uint40 currentTrancheTimestamp = tranches[1].timestamp;
        uint256 index = 1;

        // Using unchecked arithmetic is safe here because the sums of the tranche amounts are equal to the total amount
        // at this point.
        unchecked {
            while (currentTrancheTimestamp <= currentTime) {
                streamedAmount += tranches[index].amount;
                index += 1;
                currentTrancheTimestamp = tranches[index].timestamp;
            }
        }

        return streamedAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _createWithTimestamps(LockupTranched.CreateWithTimestamps memory params)
        internal
        returns (uint256 streamId)
    {
        // Safe Interactions: query the protocol fee. This is safe because it's a known Sablier contract that does
        // not call other unknown contracts.
        UD60x18 protocolFee = comptroller.protocolFees(params.asset);

        // Checks: check the fees and calculate the fee amounts.
        Lockup.CreateAmounts memory createAmounts =
            Helpers.checkAndCalculateFees(params.totalAmount, protocolFee, params.broker.fee, MAX_FEE);

        // Checks: validate the user-provided parameters.
        Helpers.checkCreateWithTimestamps(createAmounts.deposit, params.tranches, MAX_TRANCHE_COUNT, params.startTime);

        // Load the stream id in a variable.
        streamId = nextStreamId;

        // Effects: create the stream.
        Lockup.Stream storage stream = _streams[streamId];
        stream.amounts.deposited = createAmounts.deposit;
        stream.asset = params.asset;
        stream.isCancelable = params.cancelable;
        stream.isTransferable = params.transferable;
        stream.isStream = true;
        stream.sender = params.sender;
        stream.startTime = params.startTime;

        unchecked {
            // The tranche count cannot be zero at this point.
            uint256 trancheCount = params.tranches.length;
            stream.endTime = params.tranches[trancheCount - 1].timestamp;

            // Effects: store the tranches. Since Solidity lacks a syntax for copying arrays directly from
            // memory to storage, a manual approach is necessary. See https://github.com/ethereum/solidity/issues/12783.
            for (uint256 i = 0; i < trancheCount; ++i) {
                _tranches[streamId].push(params.tranches[i]);
            }

            // Effects: bump the next stream id and record the protocol fee.
            // Using unchecked arithmetic because these calculations cannot realistically overflow, ever.
            nextStreamId = streamId + 1;
            protocolRevenues[params.asset] = protocolRevenues[params.asset] + createAmounts.protocolFee;
        }

        // Effects: mint the NFT to the recipient.
        _mint({ to: params.recipient, tokenId: streamId });

        // Interactions: transfer the deposit and the protocol fee.
        // Using unchecked arithmetic because the deposit and the protocol fee are bounded by the total amount.
        unchecked {
            params.asset.safeTransferFrom({
                from: msg.sender,
                to: address(this),
                value: createAmounts.deposit + createAmounts.protocolFee
            });
        }

        // Interactions: pay the broker fee, if not zero.
        if (createAmounts.brokerFee > 0) {
            params.asset.safeTransferFrom({ from: msg.sender, to: params.broker.account, value: createAmounts.brokerFee });
        }

        // Log the newly created stream.
        emit ISablierV2LockupTranched.CreateLockupTranchedStream({
            streamId: streamId,
            funder: msg.sender,
            sender: params.sender,
            recipient: params.recipient,
            amounts: createAmounts,
            asset: params.asset,
            cancelable: params.cancelable,
            transferable: params.transferable,
            tranches: params.tranches,
            range: LockupTranched.Range({ start: stream.startTime, end: stream.endTime }),
            broker: params.broker.account
        });
    }
}
