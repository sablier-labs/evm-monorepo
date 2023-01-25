// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
import { IERC3156FlashBorrower } from "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";

import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { LockupCreateAmounts, Range, Segment } from "../types/Structs.sol";

/// @title Events
/// @notice Library with events emitted across all contracts.
library Events {
    /*//////////////////////////////////////////////////////////////////////////
                                     SABLIER-V2
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the contract admin claims all protocol revenues accrued for the provided ERC-20 asset.
    /// @param admin The address of the current contract admin.
    /// @param asset The contract address of the ERC-20 asset the protocol revenues have been claimed for.
    /// @param protocolRevenues The amount of protocol revenues claimed, in units of the asset's decimals.
    event ClaimProtocolRevenues(address indexed admin, IERC20 indexed asset, uint128 protocolRevenues);

    /// @notice Emitted when the contract admin sets a new comptroller contract.
    /// @param admin The address of the current contract admin.
    /// @param oldComptroller The address of the old {SablierV2Comptroller} contract.
    /// @param newComptroller The address of the new {SablierV2Comptroller} contract.
    event SetComptroller(
        address indexed admin,
        ISablierV2Comptroller oldComptroller,
        ISablierV2Comptroller newComptroller
    );

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-COMPTROLLER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin sets a new flash fee.
    /// @param admin The address of the current contract admin.
    /// @param oldFlashFee The old flash fee, as an UD60x18 number.
    /// @param newFlashFee The new flash fee, as an UD60x18 number.
    event SetFlashFee(address indexed admin, UD60x18 oldFlashFee, UD60x18 newFlashFee);

    /// @notice Emitted when the contract admin sets a new protocol fee for the provided ERC-20 asset.
    /// @param admin The address of the current contract admin.
    /// @param asset The contract address of the ERC-20 asset the new protocol fee was set for.
    /// @param oldProtocolFee The old protocol fee, as an UD60x18 number.
    /// @param newProtocolFee The new protocol fee, as an UD60x18 number.
    event SetProtocolFee(address indexed admin, IERC20 indexed asset, UD60x18 oldProtocolFee, UD60x18 newProtocolFee);

    /// @notice Emitted when the admin enables or disables an ERC-20 asset for flash loaning.
    /// @param admin The address of the current contract admin.
    /// @param asset The contract address of the ERC-20 asset to toggle.
    /// @param newFlag Whether the ERC-20 asset can be flash loaned.
    event ToggleFlashAsset(address indexed admin, IERC20 indexed asset, bool newFlag);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a flash loan is executed.
    /// @param receiver The address of the flash borrower.
    /// @param initiator The address of the flash loan initiator.
    /// @param asset The address of the ERC-20 asset that was flash loaned.
    /// @param amount The amount of `asset` flash loaned.
    /// @param feeAmount The fee amount of `asset` charged by the protocol.
    /// @param data The data passed to the flash borrower.
    event FlashLoan(
        address indexed initiator,
        IERC3156FlashBorrower indexed receiver,
        IERC20 indexed asset,
        uint256 amount,
        uint256 feeAmount,
        bytes data
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a lockup stream is canceled.
    /// @param streamId The id of the stream.
    /// @param sender The address of the sender.
    /// @param recipient The address of the recipient.
    /// @param senderAmount The amount of ERC-20 assets returned to the sender, in units of the asset's decimals.
    /// @param recipientAmount The amount of ERC-20 assets withdrawn to the recipient, in units of the asset's decimals.
    event CancelLockupStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    );

    /// @notice Emitted when a lockup linear stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address from which to stream the assets, who will have the ability to cancel the stream.
    /// @param recipient The address toward which to stream the assets.
    /// @param amounts A struct that encapsulates (i) the net deposit amount, (ii) the protocol fee amount, and (iii)
    /// the broker fee amount, each in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable A boolean that indicates whether the stream will be cancelable or not.
    /// @param range A struct that encapsulates (i) the start time of the stream, (ii) the cliff time of the stream,
    /// and (iii) the stop time of the stream, all as Unix timestamps.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateLockupLinearStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        LockupCreateAmounts amounts,
        IERC20 asset,
        bool cancelable,
        Range range,
        address broker
    );

    /// @notice Emitted when a lockup pro stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address from which to stream the assets, who will have the ability to cancel the stream.
    /// @param recipient The address toward which to stream the assets.
    /// @param amounts A struct that encapsulates (i) the net deposit amount, (ii) the protocol fee amount, and (iii)
    /// the broker fee amount, each in units of the asset's decimals.
    /// @param segments The segments the protocol uses to compose the custom streaming curve.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable A boolean that indicates whether the stream will be cancelable or not.
    /// @param startTime The Unix timestamp for when the stream will start.
    /// @param stopTime The Unix timestamp for when the stream will stop.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateLockupProStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        LockupCreateAmounts amounts,
        Segment[] segments,
        IERC20 asset,
        bool cancelable,
        uint40 startTime,
        uint40 stopTime,
        address broker
    );

    /// @notice Emitted when a sender makes a lockup stream non-cancelable.
    /// @param streamId The id of the stream.
    event RenounceLockupStream(uint256 indexed streamId);

    /// @notice Emitted when assets are withdrawn from a lockup stream.
    /// @param streamId The id of the stream.
    /// @param to The address that has received the withdrawn assets.
    /// @param amount The amount of assets withdrawn, in units of the asset's decimals.
    event WithdrawFromLockupStream(uint256 indexed streamId, address indexed to, uint128 amount);
}
