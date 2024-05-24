// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2OpenEndedState } from "./ISablierV2OpenEndedState.sol";
import { Broker } from "../types/DataTypes.sol";

/// @title ISablierV2OpenEnded
/// @notice Creates and manages Open Ended streams with linear streaming functions.
interface ISablierV2OpenEnded is
    ISablierV2OpenEndedState // 3 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the sender changes the rate per second.
    /// @param streamId The ID of the stream.
    /// @param recipientAmount The amount of assets that the recipient is able to withdraw, denoted in 18 decimals.
    /// @param oldRatePerSecond The rate per second to change.
    /// @param newRatePerSecond The newly changed rate per second.
    event AdjustOpenEndedStream(
        uint256 indexed streamId, uint128 recipientAmount, uint128 oldRatePerSecond, uint128 newRatePerSecond
    );

    /// @notice Emitted when a open-ended stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param sender The address from which to stream the assets, which has the ability to
    /// adjust and pause the stream.
    /// @param recipient The address toward which to stream the assets.
    /// @param ratePerSecond The amount of assets that is increasing by every second.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param lastTimeUpdate The Unix timestamp for the streamed amount calculation.
    event CreateOpenEndedStream(
        uint256 streamId,
        address indexed sender,
        address indexed recipient,
        uint128 ratePerSecond,
        IERC20 asset,
        uint40 lastTimeUpdate
    );

    /// @notice Emitted when a open-ended stream is funded.
    /// @param streamId The ID of the open-ended stream.
    /// @param funder The address which funded the stream.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param depositAmount The amount of assets deposited into the stream, denoted in 18 decimals.
    event DepositOpenEndedStream(
        uint256 indexed streamId, address indexed funder, IERC20 indexed asset, uint128 depositAmount
    );

    /// @notice Emitted when a open-ended stream is paused.
    /// @param streamId The ID of the stream.
    /// @param sender The address of the stream's sender.
    /// @param recipient The address of the stream's recipient.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param recipientAmount The amount of assets left for the stream's recipient to withdraw, denoted in 18 decimals.
    event PauseOpenEndedStream(
        uint256 streamId,
        address indexed sender,
        address indexed recipient,
        IERC20 indexed asset,
        uint128 recipientAmount
    );

    /// @notice Emitted when assets are refunded from a open-ended stream.
    /// @param streamId The ID of the open-ended stream.
    /// @param sender The address of the stream's sender.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param refundAmount The amount of assets refunded to the sender, denoted in 18 decimals.
    event RefundFromOpenEndedStream(
        uint256 indexed streamId, address indexed sender, IERC20 indexed asset, uint128 refundAmount
    );

    /// @notice Emitted when a open-ended stream is re-started.
    /// @param streamId The ID of the open-ended stream.
    /// @param sender The address of the stream's sender.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    event RestartOpenEndedStream(
        uint256 indexed streamId, address indexed sender, IERC20 indexed asset, uint128 ratePerSecond
    );

    /// @notice Emitted when assets are withdrawn from a open-ended stream.
    /// @param streamId The ID of the stream.
    /// @param to The address that has received the withdrawn assets.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param withdrawnAmount The amount of assets withdrawn, denoted in 18 decimals.
    event WithdrawFromOpenEndedStream(
        uint256 indexed streamId, address indexed to, IERC20 indexed asset, uint128 withdrawnAmount
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the timestamp at which the stream depletes its balance and starts to accumulate debt.
    /// @dev Reverts if `streamId` refers to a paused or a null stream.
    ///
    /// Notes:
    /// - If the stream has no debt, it returns the timestamp when the debt begins based on current balance and rps.
    /// - If the stream has debt, it returns 0.
    ///
    /// @param streamId The stream ID for the query.
    /// @return depletionTime The UNIX timestamp.
    function depletionTimeOf(uint256 streamId) external view returns (uint40 depletionTime);

    /// @notice Calculates the amount that the sender can refund from stream, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @return refundableAmount The amount that the sender can refund.
    function refundableAmountOf(uint256 streamId) external view returns (uint128 refundableAmount);

    /// @notice Calculates the amount that the sender can refund from stream at `time`, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @param time The Unix timestamp for the streamed amount calculation.
    /// @return refundableAmount The amount that the sender can refund.
    function refundableAmountOf(uint256 streamId, uint40 time) external view returns (uint128 refundableAmount);

    /// @notice Calculates the amount that the sender owes on the stream, i.e. if more assets have been streamed than
    /// its balance, denoted in 18 decimals. If there is no debt, it will return zero.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function streamDebtOf(uint256 streamId) external view returns (uint128 debt);

    /// @notice Calculates the amount streamed to the recipient from the last time update to the current time,
    /// denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null or a paused stream.
    /// @param streamId The stream ID for the query.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /// @notice Calculates the amount streamed to the recipient from the last time update to `time` passed as parameter,
    /// denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null or a paused stream.
    /// @param streamId The stream ID for the query.
    /// @param time The Unix timestamp for the streamed amount calculation.
    function streamedAmountOf(uint256 streamId, uint40 time) external view returns (uint128 streamedAmount);

    /// @notice Calculates the amount that the recipient can withdraw from the stream, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function withdrawableAmountOf(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /// @notice Calculates the amount that the recipient can withdraw from the stream at `time`, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @param time The Unix timestamp for the streamed amount calculation.
    function withdrawableAmountOf(uint256 streamId, uint40 time) external view returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Changes the stream's rate per second.
    ///
    /// @dev Emits a {Transfer} and {AdjustOpenEndedStream} event.
    ///
    /// Notes:
    /// - The streamed assets, until the adjustment moment, will be summed up to the remaining amount.
    /// - This function updates stream's `lastTimeUpdate` to the current block timestamp.
    ///
    /// Requiremenets:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream or a paused stream.
    /// - `msg.sender` must be the stream's sender.
    /// - `newRatePerSecond` must be greater than zero and not equal to the current rate per second.
    ///
    /// @param streamId The ID of the stream to adjust.
    /// @param newRatePerSecond The new rate per second of the open-ended stream, denoted in 18 decimals.
    function adjustRatePerSecond(uint256 streamId, uint128 newRatePerSecond) external;

    /// @notice Creates a new open-ended stream with `block.timestamp` as `lastTimeUpdate` and set stream balance to 0.
    /// The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateOpenEndedStream} event.
    ///
    /// Requiremenets:
    /// - Must not be delegate called.
    /// - `recipient` must not be the zero address.
    /// - `sender` must not be the zero address.
    /// - `ratePerSecond` must be greater than zero.
    /// - 'asset' must have valid decimals.
    ///
    /// @param recipient The address receiving the assets.
    /// @param sender The address streaming the assets, with the ability to adjust and pause the stream. It doesn't
    /// have to be the same as `msg.sender`.
    /// @param sender The address streaming the assets. It doesn't have to be the same as `msg.sender`.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @return streamId The ID of the newly created stream.
    function create(
        address recipient,
        address sender,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a new open-ended stream with `block.timestamp` as `lastTimeUpdate` and set the stream balance to
    /// `amount`. The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateOpenEndedStream}, {Transfer} and {DepositOpenEndedStream} events.
    ///
    /// Requirements:
    /// - Refer to the requirements in {create} and {deposit}.
    ///
    /// @param recipient The address receiving the assets.
    /// @param sender The address streaming the assets. It doesn't have to be the same as `msg.sender`.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @param amount The amount deposited in the stream.
    /// @return streamId The ID of the newly created stream.
    function createAndDeposit(
        address recipient,
        address sender,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable,
        uint128 amount
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a new open-ended stream with `block.timestamp` as `lastTimeUpdate` and set the stream balance to
    /// an amount calculated from the `totalAmount` after broker fee amount deduction. The stream is wrapped in an
    /// ERC-721 NFT.
    ///
    /// @dev Emits a {CreateOpenEndedStream}, {Transfer} and {DepositOpenEndedStream} events.
    ///
    /// Requirements:
    /// - Refer to the requirements in {create} and {depositViaBroker}.
    ///
    /// @param recipient The address receiving the assets.
    /// @param sender The address streaming the assets. It doesn't have to be the same as `msg.sender`.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @param totalAmount The total amount, including the stream deposit and broker fee amount, both denoted in 18
    /// decimals.
    /// @param broker The broker's address and fee.
    /// @return streamId The ID of the newly created stream.
    function createAndDepositViaBroker(
        address recipient,
        address sender,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable,
        uint128 totalAmount,
        Broker calldata broker
    )
        external
        returns (uint256 streamId);

    /// @notice Deposits assets in a stream.
    ///
    /// @dev Emits a {Transfer} and {DepositOpenEndedStream} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `amount` must be greater than zero.
    ///
    /// @param streamId The ID of the stream to deposit on.
    /// @param amount The amount deposited in the stream, denoted in 18 decimals.
    function deposit(uint256 streamId, uint128 amount) external;

    /// @notice Deposits assets in a stream.
    ///
    /// @dev Emits a {Transfer} and {DepositOpenEndedStream} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `totalAmount` must be greater than zero. Otherwise it will revert inside {deposit}.
    /// - `broker.account` must not be 0 address.
    /// - `broker.fee` must not be greater than `MAX_BROKER_FEE`. It can be zero.
    ///
    /// @param streamId The ID of the stream to deposit on.
    /// @param totalAmount The total amount, including the stream deposit and broker fee amount, both denoted in 18
    /// decimals.
    /// @param broker The broker's address and fee.
    function depositViaBroker(uint256 streamId, uint128 totalAmount, Broker calldata broker) external;

    /// @notice Pauses the stream and refunds available assets to the sender.
    ///
    /// @dev Emits a {Transfer} and {PauseOpenEndedStream} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream or an already paused stream.
    /// - `msg.sender` must be the stream's sender.
    ///
    /// @param streamId The ID of the stream to pause.
    function pause(uint256 streamId) external;

    /// @notice Refunds the provided amount of assets from the stream to the sender's address.
    ///
    /// @dev Emits a {Transfer} and {RefundFromOpenEndedStream} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `msg.sender` must be the sender.
    /// - `amount` must be greater than zero and must not exceed the refundable amount.
    ///
    /// @param streamId The ID of the stream to refund from.
    /// @param amount The amount to refund, denoted in 18 decimals.
    function refundFromStream(uint256 streamId, uint128 amount) external;

    /// @notice Restarts the stream with the provided rate per second.
    ///
    /// @dev Emits a {RestartOpenEndedStream} event.
    ///   - This function updates stream's `lastTimeUpdate` to the current block timestamp.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `streamId` must not reference a paused stream.
    /// - `msg.sender` must be the stream's sender.
    /// - `ratePerSecond` must be greater than zero.
    ///
    /// @param streamId The ID of the stream to restart.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    function restartStream(uint256 streamId, uint128 ratePerSecond) external;

    /// @notice Restarts the stream with the provided rate per second, and deposits `amount` in the stream
    /// balance.
    ///
    /// @dev Emits a {RestartOpenEndedStream}, {Transfer} and {DepositOpenEndedStream} event.
    ///
    /// Requirements:
    /// - `amount` must be greater than zero.
    /// - Refer to the requirements in {restartStream}.
    ///
    /// @param streamId The ID of the stream to restart.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param amount The amount deposited in the stream.
    function restartStreamAndDeposit(uint256 streamId, uint128 ratePerSecond, uint128 amount) external;

    /// @notice Withdraws the amount of assets calculated based on time reference and the remaining amount, from the
    /// stream to the provided `to` address.
    ///
    /// @dev Emits a {Transfer} and {WithdrawFromOpenEndedStream} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `to` must not be the zero address.
    /// - `to` must be the recipient if `msg.sender` is not the stream's recipient.
    /// - `time` must be greater than the stream's `lastTimeUpdate` and must not be in the future.
    /// -  The stream balance must be greater than zero.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn assets.
    /// @param time The Unix timestamp for the streamed amount calculation.
    function withdrawAt(uint256 streamId, address to, uint40 time) external;

    /// @notice Withdraws the maximum withdrawable amount from the stream to the provided address `to`.
    ///
    /// @dev Emits a {Transfer}, {WithdrawFromOpenEndedStream} event.
    ///
    /// Requirements:
    /// - Refer to the requirements in {withdrawAt}.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn assets.
    function withdrawMax(uint256 streamId, address to) external;
}
