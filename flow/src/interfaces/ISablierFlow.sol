// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { IBatch } from "@sablier/evm-utils/src/interfaces/IBatch.sol";
import { IComptrollerable } from "@sablier/evm-utils/src/interfaces/IComptrollerable.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { Flow } from "../types/DataTypes.sol";
import { IFlowNFTDescriptor } from "./IFlowNFTDescriptor.sol";
import { ISablierFlowState } from "./ISablierFlowState.sol";

/// @title ISablierFlow
/// @notice Creates and manages Flow streams with linear streaming functions.
interface ISablierFlow is
    IBatch, // 0 inherited components
    IComptrollerable, // 0 inherited components
    IERC4906, // 2 inherited components
    IERC721Metadata, // 2 inherited components
    ISablierFlowState // 0 inherited components
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
    /// @param snapshotTime The timestamp when the stream begins accumulating debt.
    /// @param token The contract address of the ERC-20 token to be streamed.
    /// @param transferable Boolean indicating whether the stream NFT is transferable or not.
    event CreateFlowStream(
        uint256 streamId,
        address indexed sender,
        address indexed recipient,
        UD21x18 ratePerSecond,
        uint40 snapshotTime,
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

    /// @notice Emitted when the comptroller recovers the surplus amount of token.
    /// @param comptroller The address of the current comptroller.
    /// @param token The address of the ERC-20 token the surplus amount has been recovered for.
    /// @param to The address the surplus amount has been sent to.
    /// @param surplus The amount of surplus tokens recovered.
    event Recover(ISablierComptroller indexed comptroller, IERC20 indexed token, address to, uint256 surplus);

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

    /// @notice Emitted when the native token address is set by the comptroller.
    event SetNativeToken(ISablierComptroller indexed comptroller, address nativeToken);

    /// @notice Emitted when the comptroller sets a new NFT descriptor contract.
    /// @param comptroller The address of the current comptroller.
    /// @param oldNFTDescriptor The address of the old NFT descriptor contract.
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    event SetNFTDescriptor(
        ISablierComptroller indexed comptroller,
        IFlowNFTDescriptor oldNFTDescriptor,
        IFlowNFTDescriptor newNFTDescriptor
    );

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
    /// @param withdrawAmount The amount withdrawn to the recipient, denoted in token's decimals.
    event WithdrawFromFlowStream(
        uint256 indexed streamId, address indexed to, IERC20 indexed token, address caller, uint128 withdrawAmount
    );

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Calculates the minimum fee in wei required to withdraw from the given stream ID.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function calculateMinFeeWei(uint256 streamId) external view returns (uint256 minFeeWei);

    /// @notice Returns the amount of debt covered by the stream balance, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function coveredDebtOf(uint256 streamId) external view returns (uint128 coveredDebt);

    /// @notice Returns the time at which the total debt exceeds stream balance. If the total debt exceeds the stream
    /// balance, it returns 0.
    /// @dev Reverts on the following conditions:
    /// - If `streamId` references a paused or a null stream.
    /// - If stream balance is zero.
    /// @param streamId The stream ID for the query.
    function depletionTimeOf(uint256 streamId) external view returns (uint256 depletionTime);

    /// @notice Retrieves the stream's recipient.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Returns the amount of debt accrued since the snapshot time until now, denoted as a fixed-point number
    /// where 1e18 is 1 token. If the stream is pending, it returns zero.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function ongoingDebtScaledOf(uint256 streamId) external view returns (uint256 ongoingDebtScaled);

    /// @notice Returns the amount that the sender can be refunded from the stream, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function refundableAmountOf(uint256 streamId) external view returns (uint128 refundableAmount);

    /// @notice Returns the stream's status.
    /// @dev Reverts if `streamId` references a null stream.
    /// Integrators should exercise caution when depending on the return value of this function as streams can be paused
    /// and resumed at any moment.
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
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Changes the stream's rate per second.
    ///
    /// @dev Emits a {AdjustFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - If the snapshot time is not in the future, it updates both the snapshot time and snapshot debt.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null, paused, or voided stream.
    /// - `msg.sender` must be the stream's sender.
    /// - `newRatePerSecond` must be greater than zero and must be different from the current rate per second.
    ///
    /// @param streamId The ID of the stream to adjust.
    /// @param newRatePerSecond The new rate per second, denoted as a fixed-point number where 1e18 is 1 token
    /// per second.
    function adjustRatePerSecond(uint256 streamId, UD21x18 newRatePerSecond) external payable;

    /// @notice Creates a new Flow stream by setting the snapshot time to `startTime` and leaving the balance to
    /// zero. The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateFlowStream} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `sender` must not be the zero address.
    /// - `recipient` must not be the zero address.
    /// - If `startTime` is in the future, the `ratePerSecond` must be greater than zero.
    /// - The `token` must not be the native token.
    /// - The `token`'s decimals must be less than or equal to 18.
    ///
    /// @param sender The address streaming the tokens, which is able to adjust and pause the stream. It doesn't
    /// have to be the same as `msg.sender`.
    /// @param recipient The address receiving the tokens.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    /// @param startTime The timestamp when the stream starts. A sentinel value of zero means the stream will be created
    /// with the snapshot time as `block.timestamp`.
    /// @param token The contract address of the ERC-20 token to be streamed.
    /// @param transferable Boolean indicating if the stream NFT is transferable.
    ///
    /// @return streamId The ID of the newly created stream.
    function create(
        address sender,
        address recipient,
        UD21x18 ratePerSecond,
        uint40 startTime,
        IERC20 token,
        bool transferable
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Creates a new Flow stream by setting the snapshot time to `startTime` and the balance to `amount`.
    /// The stream is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateFlowStream}, {DepositFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - Refer to the notes in {create} and {deposit}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {create} and {deposit}.
    ///
    /// @param sender The address streaming the tokens. It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address receiving the tokens.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    /// @param startTime The timestamp when the stream starts. A sentinel value of zero means the stream will be created
    /// with the snapshot time as `block.timestamp`.
    /// @param token The contract address of the ERC-20 token to be streamed.
    /// @param transferable Boolean indicating if the stream NFT is transferable.
    /// @param amount The deposit amount, denoted in token's decimals.
    ///
    /// @return streamId The ID of the newly created stream.
    function createAndDeposit(
        address sender,
        address recipient,
        UD21x18 ratePerSecond,
        uint40 startTime,
        IERC20 token,
        bool transferable,
        uint128 amount
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Makes a deposit in a stream.
    ///
    /// @dev Emits a {Transfer}, {DepositFlowStream} and {MetadataUpdate} event.
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
    function deposit(uint256 streamId, uint128 amount, address sender, address recipient) external payable;

    /// @notice Deposits tokens in a stream and pauses it.
    ///
    /// @dev Emits a {Transfer}, {DepositFlowStream}, {PauseFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - Refer to the notes in {deposit} and {pause}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {deposit} and {pause}.
    ///
    /// @param streamId The ID of the stream to deposit to, and then pause.
    /// @param amount The deposit amount, denoted in token's decimals.
    function depositAndPause(uint256 streamId, uint128 amount) external payable;

    /// @notice Pauses the stream.
    ///
    /// @dev Emits a {PauseFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - It updates snapshot debt and snapshot time.
    /// - It sets the rate per second to zero.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null, pending or paused stream.
    /// - `msg.sender` must be the stream's sender.
    ///
    /// @param streamId The ID of the stream to pause.
    function pause(uint256 streamId) external payable;

    /// @notice Recover the surplus amount of tokens.
    ///
    /// @dev Emits a {Recover} event.
    ///
    /// Notes:
    /// - The surplus amount is defined as the difference between the total balance of the contract for the provided
    /// ERC-20 token and the sum of balances of all streams created using the same ERC-20 token.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller contract.
    /// - The surplus amount must be greater than zero.
    ///
    /// @param token The contract address of the ERC-20 token to recover for.
    /// @param to The address to send the surplus amount.
    function recover(IERC20 token, address to) external;

    /// @notice Refunds the provided amount of tokens from the stream to the sender's address.
    ///
    /// @dev Emits a {Transfer}, {RefundFromFlowStream} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `msg.sender` must be the sender.
    /// - `amount` must be greater than zero and must not exceed the refundable amount.
    ///
    /// @param streamId The ID of the stream to refund from.
    /// @param amount The amount to refund, denoted in token's decimals.
    function refund(uint256 streamId, uint128 amount) external payable;

    /// @notice Refunds the provided amount of tokens from the stream to the sender's address.
    ///
    /// @dev Emits a {Transfer}, {RefundFromFlowStream}, {PauseFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - Refer to the notes in {pause}.
    ///
    /// Requirements:
    /// - Refer to the requirements in {refund} and {pause}.
    ///
    /// @param streamId The ID of the stream to refund from and then pause.
    /// @param amount The amount to refund, denoted in token's decimals.
    function refundAndPause(uint256 streamId, uint128 amount) external payable;

    /// @notice Refunds the entire refundable amount of tokens from the stream to the sender's address.
    ///
    /// @dev Emits a {Transfer}, {RefundFromFlowStream} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - Refer to the requirements in {refund}.
    ///
    /// @param streamId The ID of the stream to refund from.
    ///
    /// @return refundedAmount The amount refunded to the stream sender, denoted in token's decimals.
    function refundMax(uint256 streamId) external payable returns (uint128 refundedAmount);

    /// @notice Restarts the stream with the provided rate per second.
    ///
    /// @dev Emits a {RestartFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - It updates snapshot debt and snapshot time.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream, must be paused, and must not be voided.
    /// - `msg.sender` must be the stream's sender.
    /// - `ratePerSecond` must be greater than zero.
    ///
    /// @param streamId The ID of the stream to restart.
    /// @param ratePerSecond The amount by which the debt is increasing every second, denoted as a fixed-point number
    /// where 1e18 is 1 token per second.
    function restart(uint256 streamId, UD21x18 ratePerSecond) external payable;

    /// @notice Restarts the stream with the provided rate per second, and makes a deposit.
    ///
    /// @dev Emits a {RestartFlowStream}, {Transfer}, {DepositFlowStream} and {MetadataUpdate} event.
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
    function restartAndDeposit(uint256 streamId, UD21x18 ratePerSecond, uint128 amount) external payable;

    /// @notice Sets the native token address. Once set, it cannot be changed.
    /// @dev For more information, see the documentation for {nativeToken}.
    ///
    /// Emits a {SetNativeToken} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller contract.
    /// - `newNativeToken` must not be zero address.
    /// - The native token must not be already set.
    /// @param newNativeToken The address of the native token.
    function setNativeToken(address newNativeToken) external;

    /// @notice Sets a new NFT descriptor contract, which produces the URI describing the Sablier stream NFTs.
    ///
    /// @dev Emits a {SetNFTDescriptor} and {BatchMetadataUpdate} event.
    ///
    /// Notes:
    /// - Does not revert if the NFT descriptor is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the comptroller contract.
    ///
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    function setNFTDescriptor(IFlowNFTDescriptor newNFTDescriptor) external;

    /// @notice A helper to transfer ERC-20 tokens from the caller to the provided address. Useful for paying one-time
    /// bonuses.
    ///
    /// @dev Emits a {Transfer} event.
    ///
    /// Requirements:
    /// - `msg.sender` must have approved this contract to spend at least `amount` tokens.
    ///
    /// @param token The contract address of the ERC-20 token to be transferred.
    /// @param to The address receiving the tokens.
    /// @param amount The amount of tokens to transfer, denoted in token's decimals.
    function transferTokens(IERC20 token, address to, uint128 amount) external payable;

    /// @notice Voids a stream.
    ///
    /// @dev Emits a {VoidFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - It sets snapshot time to the `block.timestamp`.
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
    function void(uint256 streamId) external payable;

    /// @notice Withdraws the provided `amount` to the provided `to` address.
    ///
    /// @dev Emits a {Transfer}, {WithdrawFromFlowStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - It sets the snapshot time to the `block.timestamp` if `amount` is greater than snapshot debt.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `streamId` must not reference a null stream.
    /// - `to` must not be the zero address.
    /// - `to` must be the recipient if `msg.sender` is not the stream's recipient or an approved third party.
    /// - `amount` must  be greater than zero and must not exceed the withdrawable amount.
    ///
    /// @param streamId The ID of the stream to withdraw from.
    /// @param to The address receiving the withdrawn tokens.
    /// @param amount The amount to withdraw, denoted in token's decimals.
    function withdraw(uint256 streamId, address to, uint128 amount) external payable;

    /// @notice Withdraws the entire withdrawable amount to the provided `to` address.
    ///
    /// @dev Emits a {Transfer}, {WithdrawFromFlowStream} and {MetadataUpdate} event.
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
    function withdrawMax(uint256 streamId, address to) external payable returns (uint128 withdrawnAmount);
}
