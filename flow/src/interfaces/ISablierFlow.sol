// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

import { Broker, Flow } from "./../types/DataTypes.sol";
import { ISablierFlowBase } from "./ISablierFlowBase.sol";

/// @title ISablierFlow
/// @notice Creates and manages Flow streams with linear streaming functions.
interface ISablierFlow is
    ISablierFlowBase // 4 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the rate per second is updated by the sender.
    /// @param streamId The ID of the stream.
    /// @param totalDebt The total debt at the time of the update, denoted in token's decimals.
    /// @param oldRatePerSecond The old rate per second, denoted as a fixed-point number where 1e18 is 1 token
    /// per second.
    /// @param newRatePerSecond The new rate per second, denoted as a fixed-point number where 1e18 is 1 token
    /// per second.
    event AdjustFlowStream(
        uint256 indexed streamId, uint256 totalDebt, UD21x18 oldRatePerSecond, UD21x18 newRatePerSecond
    );

    /// @notice Emitted when a Flow stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param sender The address streaming the tokens, which is able to adjust and pause the stream.
    /// @param recipient The address receiving the tokens, as well as the NFT owner.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    /// @param token The contract address of the ERC-20 token to be streamed.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    event CreateFlowStream(
        uint256 streamId,
        address indexed sender,
        address indexed recipient,
        UD21x18 ratePerSecond,
        IERC20 indexed token,
        bool transferable
    );

    /// @notice Emitted when a stream is funded.
    /// @param streamId The ID of the stream.
    /// @param funder The address that made the deposit.
    /// @param amount The amount of tokens deposited into the stream, denoted in token's decimals.
    event DepositFlowStream(uint256 indexed streamId, address indexed funder, uint128 amount);

    /// @notice Emitted when a stream is paused by the sender.
    /// @param streamId The ID of the stream.
    /// @param sender The stream's sender address.
    /// @param recipient The stream's recipient address.
    /// @param totalDebt The amount of tokens owed by the sender to the recipient, denoted in token's decimals.
    event PauseFlowStream(
        uint256 indexed streamId, address indexed sender, address indexed recipient, uint256 totalDebt
    );

    /// @notice Emitted when a sender is refunded from a stream.
    /// @param streamId The ID of the stream.
    /// @param sender The stream's sender address.
    /// @param amount The amount of tokens refunded to the sender, denoted in token's decimals.
    event RefundFromFlowStream(uint256 indexed streamId, address indexed sender, uint128 amount);

    /// @notice Emitted when a stream is restarted by the sender.
    /// @param streamId The ID of the stream.
    /// @param sender The stream's sender address.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    event RestartFlowStream(uint256 indexed streamId, address indexed sender, UD21x18 ratePerSecond);

    /// @notice Emitted when a stream is voided by the sender, recipient or an approved operator.
    /// @param streamId The ID of the stream.
    /// @param sender The stream's sender address.
    /// @param recipient The stream's recipient address.
    /// @param caller The address that performed the void, which can be the sender, recipient or an approved operator.
    /// @param newTotalDebt The new total debt, denoted in token's decimals.
    /// @param writtenOffDebt The amount of debt written off by the caller, denoted in token's decimals.
    event VoidFlowStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        address caller,
        uint256 newTotalDebt,
        uint256 writtenOffDebt
    );

    /// @notice Emitted when tokens are withdrawn from a stream by a recipient or an approved operator.
    /// @param streamId The ID of the stream.
    /// @param to The address that received the withdrawn tokens.
    /// @param token The contract address of the ERC-20 token that was withdrawn.
    /// @param caller The address that performed the withdrawal, which can be the recipient or an approved operator.
    /// @param withdrawAmount The amount withdrawn to the recipient after subtracting the protocol fee, denoted in
    /// token's decimals.
    /// @param protocolFeeAmount The amount of protocol fee deducted from the withdrawn amount, denoted in token's
    /// decimals.
    event WithdrawFromFlowStream(
        uint256 indexed streamId,
        address indexed to,
        IERC20 indexed token,
        address caller,
        uint128 withdrawAmount,
        uint128 protocolFeeAmount
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the amount of debt covered by the stream balance, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function coveredDebtOf(uint256 streamId) external view returns (uint128 coveredDebt);

    /// @notice Returns the time at which the total debt exceeds stream balance. If the total debt is less than
    /// or equal to stream balance, it returns 0.
    /// @dev Reverts if `streamId` references a paused or a null stream.
    /// @param streamId The stream ID for the query.
    function depletionTimeOf(uint256 streamId) external view returns (uint256 depletionTime);

    /// @notice Returns the amount of debt accrued since the snapshot time until now, denoted as a fixed-point number
    /// where 1e18 is 1 token.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function ongoingDebtScaledOf(uint256 streamId) external view returns (uint256 ongoingDebtScaled);

    /// @notice Returns the amount that the sender can be refunded from the stream, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function refundableAmountOf(uint256 streamId) external view returns (uint128 refundableAmount);

    /// @notice Returns the stream's status.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function statusOf(uint256 streamId) external view returns (Flow.Status status);

    /// @notice Returns the total amount owed by the sender to the recipient, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function totalDebtOf(uint256 streamId) external view returns (uint256 totalDebt);

    /// @notice Returns the amount of debt not covered by the stream balance, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function uncoveredDebtOf(uint256 streamId) external view returns (uint256 uncoveredDebt);

    /// @notice Calculates the amount that the recipient can withdraw from the stream, denoted in token decimals. This
    /// is an alias for `coveredDebtOf`.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    /// @return withdrawableAmount The amount that the recipient can withdraw.
    function withdrawableAmountOf(uint256 streamId) external view returns (uint128 withdrawableAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Changes the stream's rate per second.
    ///
    /// @dev Emits {AdjustFlowStream} and {MetadataUpdate} events.
    ///
    /// Notes:
    /// - Performs a debt snapshot.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null or a paused stream.
    /// - `msg.sender` must be the stream's sender.
    /// - `newRatePerSecond` must not equal to the current rate per second.
    ///
    /// @param streamId The ID of the stream to adjust.
    /// @param newRatePerSecond The new rate per second, denoted as a fixed-point number where 1e18 is 1 token
    /// per second.
    function adjustRatePerSecond(uint256 streamId, UD21x18 newRatePerSecond) external;

    /// @notice Creates a new Flow stream by setting the snapshot time to `block.timestamp` and leaving the balance to
    /// zero. The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits {CreateFlowStream} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `sender` must not be the zero address.
    /// - `recipient` must not be the zero address.
    /// - The `token`'s decimals must be less than or equal to 18.
    ///
    /// @param sender The address streaming the tokens, which is able to adjust and pause the stream. It doesn't
    /// have to be the same as `msg.sender`.
    /// @param recipient The address receiving the tokens.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    /// @param token The contract address of the ERC-20 token to be streamed.
    /// @param transferable Boolean indicating if the stream NFT is transferable.
    ///
    /// @return streamId The ID of the newly created stream.
    function create(
        address sender,
        address recipient,
        UD21x18 ratePerSecond,
        IERC20 token,
        bool transferable
    )
        external
        returns (uint256 streamId);

    /// @notice Creates a new Flow stream by setting the snapshot time to `block.timestamp` and the balance to `amount`.
    /// The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits {Transfer}, {CreateFlowStream}, and {DepositFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {deposit}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {create} and {deposit}.
    ///
    /// @param sender The address streaming the tokens. It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address receiving the tokens.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    /// @param token The contract address of the ERC-20 token to be streamed.
    /// @param transferable Boolean indicating if the stream NFT is transferable.
    /// @param amount The deposit amount, denoted in token's decimals.
    ///
    /// @return streamId The ID of the newly created stream.
    function createAndDeposit(
        address sender,
        address recipient,
        UD21x18 ratePerSecond,
        IERC20 token,
        bool transferable,
        uint128 amount
    )
        external
        returns (uint256 streamId);

    /// @notice Makes a deposit in a stream.
    ///
    /// @dev Emits {Transfer} and {DepositFlowStream} events.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null or a voided stream.
    /// - `amount` must be greater than zero.
    /// - `sender` and `recipient` must match the stream's sender and recipient addresses.
    ///
    /// @param streamId The ID of the stream to deposit to.
    /// @param amount The deposit amount, denoted in token's decimals.
    /// @param sender The stream's sender address.
    /// @param recipient The stream's recipient address.
    function deposit(uint256 streamId, uint128 amount, address sender, address recipient) external;

    /// @notice Deposits tokens in a stream and pauses it.
    ///
    /// @dev Emits {Transfer}, {DepositFlowStream} and {PauseFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {deposit} and {pause}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {deposit} and {pause}.
    ///
    /// @param streamId The ID of the stream to deposit to, and then pause.
    /// @param amount The deposit amount, denoted in token's decimals.
    function depositAndPause(uint256 streamId, uint128 amount) external;

    /// @notice Deposits tokens in a stream.
    ///
    /// @dev Emits {Transfer} and {DepositFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {deposit}.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `totalAmount` must be greater than zero. Otherwise it will revert inside {deposit}.
    /// - `broker.account` must not be 0 address.
    /// - `broker.fee` must not be greater than `MAX_FEE`. It can be zero.
    ///
    /// @param streamId The ID of the stream to deposit on.
    /// @param totalAmount The total amount, including the deposit and any broker fee, denoted in token's decimals.
    /// @param sender The stream's sender address.
    /// @param recipient The stream's recipient address.
    /// @param broker Struct encapsulating (i) the address of the broker assisting in creating the stream, and (ii) the
    /// percentage fee paid to the broker from `totalAmount`, denoted as a fixed-point percentage.
    function depositViaBroker(
        uint256 streamId,
        uint128 totalAmount,
        address sender,
        address recipient,
        Broker calldata broker
    )
        external;

    /// @notice Pauses the stream.
    ///
    /// @dev Emits {PauseFlowStream} event.
    ///
    /// Notes:
    /// - It does not set the snapshot time to the current block timestamp.
    /// - It updates the snapshot debt by adding up ongoing debt.
    /// - It sets the rate per second to zero.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null or an already paused stream.
    /// - `msg.sender` must be the stream's sender.
    ///
    /// @param streamId The ID of the stream to pause.
    function pause(uint256 streamId) external;

    /// @notice Refunds the provided amount of tokens from the stream to the sender's address.
    ///
    /// @dev Emits {Transfer} and {RefundFromFlowStream} events.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `msg.sender` must be the sender.
    /// - `amount` must be greater than zero and must not exceed the refundable amount.
    ///
    /// @param streamId The ID of the stream to refund from.
    /// @param amount The amount to refund, denoted in token's decimals.
    function refund(uint256 streamId, uint128 amount) external;

    /// @notice Refunds the provided amount of tokens from the stream to the sender's address.
    ///
    /// @dev Emits {Transfer}, {RefundFromFlowStream} and {PauseFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {pause}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {refund} and {pause}.
    ///
    /// @param streamId The ID of the stream to refund from and then pause.
    /// @param amount The amount to refund, denoted in token's decimals.
    function refundAndPause(uint256 streamId, uint128 amount) external;

    /// @notice Restarts the stream with the provided rate per second.
    ///
    /// @dev Emits {RestartFlowStream} event.
    /// - This function updates stream's `snapshotTime` to the current block timestamp.
    ///
    /// Notes:
    /// - It sets the snapshot time to the current block timestamp.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null, or a voided stream.
    /// - `msg.sender` must be the stream's sender.
    /// - `ratePerSecond` must be greater than zero.
    ///
    /// @param streamId The ID of the stream to restart.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    function restart(uint256 streamId, UD21x18 ratePerSecond) external;

    /// @notice Restarts the stream with the provided rate per second, and makes a deposit.
    ///
    /// @dev Emits {RestartFlowStream}, {Transfer}, and {DepositFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {restart} and {deposit}.
    ///
    /// Requirements:
    /// - `amount` must be greater than zero.
    /// - Refer to the requirements in {restart}.
    ///
    /// @param streamId The ID of the stream to restart.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    /// @param amount The deposit amount, denoted in token's decimals.
    function restartAndDeposit(uint256 streamId, UD21x18 ratePerSecond, uint128 amount) external;

    /// @notice Voids a stream.
    ///
    /// @dev Emits {VoidFlowStream} event.
    ///
    /// Notes:
    /// - It sets snapshot time to the `block.timestamp`
    /// - Voiding an insolvent stream sets the snapshot debt to the stream's balance making the uncovered debt to become
    /// zero.
    /// - Voiding a solvent stream updates the snapshot debt by adding up ongoing debt.
    /// - It sets the rate per second to zero.
    /// - A voided stream cannot be restarted.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null or a voided stream.
    /// - `msg.sender` must either be the stream's sender, recipient or an approved third party.
    ///
    /// @param streamId The ID of the stream to void.
    function void(uint256 streamId) external;

    /// @notice Withdraws the provided `amount` minus the protocol fee to the provided `to` address.
    ///
    /// @dev Emits {Transfer} and {WithdrawFromFlowStream} events.
    ///
    /// Notes:
    /// - It sets the snapshot time to the `block.timestamp` if `amount` is greater than snapshot debt.
    /// - A protocol fee may be charged on the withdrawn amount if the protocol fee is enabled for the streaming token.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `to` must not be the zero address.
    /// - `to` must be the recipient if `msg.sender` is not the stream's recipient.
    /// - `amount` must  be greater than zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn tokens.
    /// @param amount The amount to withdraw, denoted in token's decimals.
    /// @return withdrawnAmount The amount withdrawn to the recipient, denoted in token's decimals. This is input amount
    /// minus the protocol fee.
    /// @return protocolFeeAmount The protocol fee amount, denoted in the token's decimals.
    function withdraw(
        uint256 streamId,
        address to,
        uint128 amount
    )
        external
        returns (uint128 withdrawnAmount, uint128 protocolFeeAmount);

    /// @notice Withdraws the entire withdrawable amount minus the protocol fee to the provided `to` address.
    ///
    /// @dev Emits {Transfer} and {WithdrawFromFlowStream} events.
    ///
    /// Notes:
    /// - Refer to the notes in {withdraw}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {withdraw}.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn tokens.
    ///
    /// @return withdrawnAmount The amount withdrawn to the recipient, denoted in token's decimals.
    /// @return protocolFeeAmount The protocol fee amount, denoted in the token's decimals.
    function withdrawMax(
        uint256 streamId,
        address to
    )
        external
        returns (uint128 withdrawnAmount, uint128 protocolFeeAmount);
}
