// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlowState } from "./ISablierFlowState.sol";
import { Broker, Flow } from "../types/DataTypes.sol";

/// @title ISablierFlow
/// @notice Creates and manages Flow streams with linear streaming functions.
interface ISablierFlow is
    ISablierFlowState // 3 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the sender changes the rate per second.
    /// @param streamId The ID of the stream.
    /// @param amountOwed The amount of assets owed by the sender to the recipient, including debt, denoted in 18
    /// decimals.
    /// @param newRatePerSecond The newly changed rate per second, denoted in 18 decimals.
    /// @param oldRatePerSecond The rate per second to change, denoted in 18 decimals.
    event AdjustFlowStream(
        uint256 indexed streamId, uint128 amountOwed, uint128 newRatePerSecond, uint128 oldRatePerSecond
    );

    /// @notice Emitted when a Flow stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param sender The address from which to stream the assets, which has the ability to adjust and pause the stream.
    /// @param recipient The address toward which to stream the assets.
    /// @param lastTimeUpdate The Unix timestamp for the recent amount calculation.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    event CreateFlowStream(
        uint256 indexed streamId,
        IERC20 indexed asset,
        address indexed sender,
        address recipient,
        uint40 lastTimeUpdate,
        uint128 ratePerSecond
    );

    /// @notice Emitted when a Flow stream is funded.
    /// @param streamId The ID of the Flow stream.
    /// @param funder The address which funded the stream.
    /// @param depositAmount The amount of assets deposited into the stream, denoted in 18 decimals.
    event DepositFlowStream(uint256 indexed streamId, address indexed funder, uint128 depositAmount);

    /// @notice Emitted when a Flow stream is paused.
    /// @param streamId The ID of the Flow stream.
    /// @param recipient The address of the stream's recipient.
    /// @param sender The address of the stream's sender.
    /// @param amountOwed The amount of assets owed by the sender to the recipient, including debt, denoted in 18
    /// decimals.
    event PauseFlowStream(uint256 indexed streamId, address recipient, address sender, uint128 amountOwed);

    /// @notice Emitted when assets are refunded from a Flow stream.
    /// @param streamId The ID of the Flow stream.
    /// @param sender The address of the stream's sender.
    /// @param refundAmount The amount of assets refunded to the sender, denoted in 18 decimals.
    event RefundFromFlowStream(uint256 indexed streamId, address indexed sender, uint128 refundAmount);

    /// @notice Emitted when a Flow stream is re-started.
    /// @param streamId The ID of the Flow stream.
    /// @param sender The address of the stream's sender.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    event RestartFlowStream(uint256 indexed streamId, address sender, uint128 ratePerSecond);

    /// @notice Emitted when a Flow stream is voided by the recipient.
    /// @param streamId The ID of the stream.
    /// @param recipient The address of the stream's recipient.
    /// @param sender The address of the stream's sender.
    /// @param newAmountOwed The updated amount of assets owed by the sender to the recipient, denoted in 18  decimals.
    /// @param writenoffDebt The debt amount written-off by the recipient.
    event VoidFlowStream(
        uint256 indexed streamId, address recipient, address sender, uint128 newAmountOwed, uint128 writenoffDebt
    );

    /// @notice Emitted when assets are withdrawn from a Flow stream.
    /// @param streamId The ID of the Flow stream.
    /// @param to The address that has received the withdrawn assets.
    /// @param withdrawnAmount The amount of assets withdrawn, denoted in 18 decimals.
    event WithdrawFromFlowStream(uint256 indexed streamId, address indexed to, uint128 withdrawnAmount);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the amount owed by the sender to the recipient, including debt, denoted in 18 decimals.
    /// @dev Reverts if `streamId` refers to a null stream.
    /// @param streamId The stream ID for the query.
    /// @return amountOwed The amount owed by the sender to the recipient.
    function amountOwedOf(uint256 streamId) external view returns (uint128 amountOwed);

    /// @notice Returns the timestamp at which the stream depletes its balance and starts to accumulate debt.
    /// @dev Reverts if `streamId` refers to a paused or a null stream.
    ///
    /// Notes:
    /// - If the stream has no debt, it returns the timestamp when the debt begins based on current balance and
    /// rate per second.
    /// - If the stream has debt, it returns 0.
    ///
    /// @param streamId The stream ID for the query.
    /// @return depletionTime The UNIX timestamp.
    function depletionTimeOf(uint256 streamId) external view returns (uint40 depletionTime);

    /// @notice Calculates the recent amount streamed to the recipient from the last time update until the current
    /// timestamp, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @return recentAmount The recent amount from the last time update until the current timestamp.
    function recentAmountOf(uint256 streamId) external view returns (uint128 recentAmount);

    /// @notice Calculates the amount that the sender can refund from stream, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @return refundableAmount The amount that the sender can refund.
    function refundableAmountOf(uint256 streamId) external view returns (uint128 refundableAmount);

    /// @notice Returns the stream's status.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function statusOf(uint256 streamId) external view returns (Flow.Status status);

    /// @notice Calculates the amount that the sender owes on the stream, i.e. if more assets have been streamed than
    /// its balance, denoted in 18 decimals. If there is no debt, it will return zero.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @return debt The amount that the sender owes on the stream.
    function streamDebtOf(uint256 streamId) external view returns (uint128 debt);

    /// @notice Calculates the amount that the recipient can withdraw from the stream, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @return withdrawableAmount The amount that the recipient can withdraw.
    function withdrawableAmountOf(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Changes the stream's rate per second.
    ///
    /// @dev Emits a {Transfer} and {AdjustFlowStream} event.
    ///
    /// Notes:
    /// - It updates `lastTimeUpdate` to the current block timestamp.
    /// - It updates the remaining amount by adding up recent amount.
    ///
    /// Requiremenets:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream or a paused stream.
    /// - `msg.sender` must be the stream's sender.
    /// - `newRatePerSecond` must be greater than zero and not equal to the current rate per second.
    ///
    /// @param streamId The ID of the stream to adjust.
    /// @param newRatePerSecond The new rate per second of the Flow stream, denoted in 18 decimals.
    function adjustRatePerSecond(uint256 streamId, uint128 newRatePerSecond) external;

    /// @notice Creates a new Flow stream with `block.timestamp` as `lastTimeUpdate` and set stream balance to 0.
    /// The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateFlowStream} event.
    ///
    /// Requiremenets:
    /// - Must not be delegate called.
    /// - `recipient` must not be the zero address.
    /// - `sender` must not be the zero address.
    /// - `ratePerSecond` must be greater than zero.
    /// - `asset` must implement `decimals` function and should not return a number greater than 255.
    /// - `asset` decimals must not be greater than 18.
    ///
    /// @param recipient The address receiving the assets.
    /// @param sender The address streaming the assets, with the ability to adjust and pause the stream. It doesn't
    /// have to be the same as `msg.sender`.
    /// @param sender The address streaming the assets. It doesn't have to be the same as `msg.sender`.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    ///
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

    /// @notice Creates a new Flow stream with `block.timestamp` as `lastTimeUpdate` and set the stream balance to
    /// `amount`. The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateFlowStream}, {Transfer} and {DepositFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {deposit}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {create} and {deposit}.
    ///
    /// @param recipient The address receiving the assets.
    /// @param sender The address streaming the assets. It doesn't have to be the same as `msg.sender`.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @param transferAmount The transfer amount, denoted in units of the asset's decimals.
    ///
    /// @return streamId The ID of the newly created stream.
    function createAndDeposit(
        address recipient,
        address sender,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable,
        uint128 transferAmount
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a new Flow stream with `block.timestamp` as `lastTimeUpdate` and set the stream balance to
    /// an amount calculated from the `totalAmount` after broker fee amount deduction. The stream is wrapped in an
    /// ERC-721 NFT.
    ///
    /// @dev Emits a {CreateFlowStream}, {Transfer} and {DepositFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {depositViaBroker}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {create} and {depositViaBroker}.
    ///
    /// @param recipient The address receiving the assets.
    /// @param sender The address streaming the assets. It doesn't have to be the same as `msg.sender`.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @param totalTransferAmount The total transfer amount, including the stream transfer amount and broker fee
    /// amount, denoted in units of the asset's decimals.
    /// @param broker The broker's address and fee.
    ///
    /// @return streamId The ID of the newly created stream.
    function createAndDepositViaBroker(
        address recipient,
        address sender,
        uint128 ratePerSecond,
        IERC20 asset,
        bool isTransferable,
        uint128 totalTransferAmount,
        Broker calldata broker
    )
        external
        returns (uint256 streamId);

    /// @notice Deposits assets in a stream.
    ///
    /// @dev Emits a {Transfer} and {DepositFlowStream} event.
    ///
    /// Notes:
    /// - If the asset has less than 18 decimals, the amount deposited will be normalized to 18 decimals before adding
    /// it to the stream balance.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `transferAmount` must be greater than zero.
    ///
    /// @param streamId The ID of the stream to deposit on.
    /// @param transferAmount The transfer amount, denoted in units of the asset's decimals.
    function deposit(uint256 streamId, uint128 transferAmount) external;

    /// @notice Deposits assets in a stream and pauses it.
    ///
    /// @dev Emits a {Transfer}, {DepositFlowStream} and {PauseFlowStream} event.
    ///
    /// Notes:
    /// - Refer to the notes in {deposit} and {pause}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {deposit} and {pause}.
    ///
    /// @param streamId The ID of the stream to deposit on and then pause.
    /// @param transferAmount The transfer amount, denoted in units of the asset's decimals.
    function depositAndPause(uint256 streamId, uint128 transferAmount) external;

    /// @notice Deposits assets in a stream.
    ///
    /// @dev Emits a {Transfer} and {DepositFlowStream} event.
    ///
    /// Notes:
    /// - Refer to the notes in {deposit}.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `totalTransferAmount` must be greater than zero. Otherwise it will revert inside {deposit}.
    /// - `broker.account` must not be 0 address.
    /// - `broker.fee` must not be greater than `MAX_BROKER_FEE`. It can be zero.
    ///
    /// @param streamId The ID of the stream to deposit on.
    /// @param totalTransferAmount The total transfer amount, including the stream transfer amount and broker fee
    /// amount, denoted in units of the  asset's decimals.
    /// @param broker The broker's address and fee.
    function depositViaBroker(uint256 streamId, uint128 totalTransferAmount, Broker calldata broker) external;

    /// @notice Pauses the stream.
    ///
    /// @dev Emits a {PauseFlowStream} event.
    ///
    /// Notes:
    /// - It does not update `lastTimeUpdate` to the current block timestamp.
    /// - It updates the remaining amount by adding up recent amount.
    /// - It sets rate per second to zero.
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
    /// @dev Emits a {Transfer} and {RefundFromFlowStream} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `msg.sender` must be the sender.
    /// - `amount` must be greater than zero and must not exceed the refundable amount.
    ///
    /// @param streamId The ID of the stream to refund from.
    /// @param amount The amount to refund, denoted in 18 decimals.
    ///
    /// @return transferAmount The amount transferred to the sender, denoted in asset's decimals.
    function refund(uint256 streamId, uint128 amount) external returns (uint128 transferAmount);

    /// @notice Refunds the provided amount of assets from the stream to the sender's address.
    ///
    /// @dev Emits a {Transfer}, {RefundFromFlowStream} and {PauseFlowStream} event.
    ///
    /// Notes:
    /// - Refer to the notes in {pause}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {refund} and {pause}.
    ///
    /// @param streamId The ID of the stream to refund from and then pause.
    /// @param amount The amount to refund, denoted in 18 decimals.
    ///
    /// @return transferAmount The amount transferred to the sender, denoted in asset's decimals.
    function refundAndPause(uint256 streamId, uint128 amount) external returns (uint128 transferAmount);

    /// @notice Restarts the stream with the provided rate per second.
    ///
    /// @dev Emits a {RestartFlowStream} event.
    ///   - This function updates stream's `lastTimeUpdate` to the current block timestamp.
    ///
    /// Notes:
    /// - It sets `lastTimeUpdate` to the current block timestamp.
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
    function restart(uint256 streamId, uint128 ratePerSecond) external;

    /// @notice Restarts the stream with the provided rate per second, and deposits in the stream.
    ///
    /// @dev Emits a {RestartFlowStream}, {Transfer} and {DepositFlowStream} event.
    ///
    /// Notes:
    /// - Refer to the notes in {restart} and {deposit}.
    ///
    /// Requirements:
    /// - `transferAmount` must be greater than zero.
    /// - Refer to the requirements in {restart}.
    ///
    /// @param streamId The ID of the stream to restart.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param transferAmount The transfer amount, denoted in units of the asset's decimals.
    function restartAndDeposit(uint256 streamId, uint128 ratePerSecond, uint128 transferAmount) external;

    /// @notice Voids the stream debt and pauses it.
    ///
    /// @dev Emits a {VoidFlowStream} event.
    ///
    /// Notes:
    /// - It sets the remaining amount to stream balance so that the stream debt becomes zero.
    /// - It sets rate per second to zero.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `msg.sender` must either be the stream's recipient or an approved third party.
    /// - stream debt must be greater than zero.
    ///
    /// Notes:
    /// - A paused stream can also be voided if its debt is not zero.
    ///
    /// @param streamId The ID of the stream to void.
    function void(uint256 streamId) external;

    /// @notice Withdraws the amount of assets calculated based on time reference and the remaining amount, from the
    /// stream to the provided `to` address.
    ///
    /// @dev Emits a {Transfer} and {WithdrawFromFlowStream} event.
    ///
    /// Notes:
    /// - It sets `lastTimeUpdate` to the `time` specified.
    /// - If stream balance is less than the amount owed at `time`:
    ///   - It withdraws the full balance.
    ///   - It sets the remaining amount to the amount owed minus the stream balance.
    /// - If stream balance is greater than the amount owed at `time`:
    ///   - It withdraws the amount owed at `time`.
    ///   - It sets the remaining amount to zero.
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
    /// @param time The Unix timestamp to calculate the recent streamed amount since last time update.
    ///
    /// @return transferAmount The amount transferred to the recipient, denoted in asset's decimals.
    function withdrawAt(uint256 streamId, address to, uint40 time) external returns (uint128 transferAmount);

    /// @notice Withdraws the maximum withdrawable amount from the stream to the provided address `to`.
    ///
    /// @dev Emits a {Transfer}, {WithdrawFromFlowStream} event.
    ///
    /// Notes:
    /// - It calls {withdrawAt} with the current block timestamp.
    /// - Refer to the notes in {withdrawAt}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {withdrawAt}.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn assets.
    ///
    /// @return transferAmount The amount transferred to the recipient, denoted in asset's decimals.
    function withdrawMax(uint256 streamId, address to) external returns (uint128 transferAmount);
}
