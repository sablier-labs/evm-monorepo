// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Lockup } from "../types/Lockup.sol";
import { LockupDynamic } from "../types/LockupDynamic.sol";
import { LockupLinear } from "../types/LockupLinear.sol";
import { LockupTranched } from "../types/LockupTranched.sol";
import { ILockupNFTDescriptor } from "./ILockupNFTDescriptor.sol";

/// @title ISablierLockupState
/// @notice Contract with state variables (storage and constants) for the {SablierLockup} contract, their respective
/// getters and helpful modifiers.
interface ISablierLockupState {
    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the aggregate amount across all streams, denoted in units of the token's decimals.
    /// @dev If tokens are directly transferred to the contract without using the stream creation functions, the
    /// ERC-20 balance may be greater than the aggregate amount.
    /// @param token The ERC-20 token for the query.
    function aggregateAmount(IERC20 token) external view returns (uint256);

    /// @notice Retrieves the stream's cliff time, which is a Unix timestamp. A value of zero means there is no cliff.
    /// @dev Reverts if `streamId` references either a null stream or a non-LL stream.
    /// @param streamId The stream ID for the query.
    function getCliffTime(uint256 streamId) external view returns (uint40 cliffTime);

    /// @notice Retrieves the amount deposited in the stream, denoted in units of the token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getDepositedAmount(uint256 streamId) external view returns (uint128 depositedAmount);

    /// @notice Retrieves the stream's end time, which is a Unix timestamp.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getEndTime(uint256 streamId) external view returns (uint40 endTime);

    /// @notice Retrieves the distribution models used to create the stream.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getLockupModel(uint256 streamId) external view returns (Lockup.Model lockupModel);

    /// @notice Retrieves the amount refunded to the sender after a cancellation, denoted in units of the token's
    /// decimals. This amount is always zero unless the stream was canceled.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getRefundedAmount(uint256 streamId) external view returns (uint128 refundedAmount);

    /// @notice Retrieves the segments used to compose the dynamic distribution function.
    /// @dev Reverts if `streamId` references either a null stream or a non-LD stream.
    /// @param streamId The stream ID for the query.
    /// @return segments See the documentation in {LockupDynamic} type.
    function getSegments(uint256 streamId) external view returns (LockupDynamic.Segment[] memory segments);

    /// @notice Retrieves the stream's sender.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Retrieves the stream's start time, which is a Unix timestamp.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getStartTime(uint256 streamId) external view returns (uint40 startTime);

    /// @notice Retrieves the tranches used to compose the tranched distribution function.
    /// @dev Reverts if `streamId` references either a null stream or a non-LT stream.
    /// @param streamId The stream ID for the query.
    /// @return tranches See the documentation in {LockupTranched} type.
    function getTranches(uint256 streamId) external view returns (LockupTranched.Tranche[] memory tranches);

    /// @notice Retrieves the address of the underlying ERC-20 token being distributed.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getUnderlyingToken(uint256 streamId) external view returns (IERC20 token);

    /// @notice Retrieves the unlock amounts used to compose the linear distribution function.
    /// @dev Reverts if `streamId` references either a null stream or a non-LL stream.
    /// @param streamId The stream ID for the query.
    /// @return unlockAmounts See the documentation in {LockupLinear} type.
    function getUnlockAmounts(uint256 streamId)
        external
        view
        returns (LockupLinear.UnlockAmounts memory unlockAmounts);

    /// @notice Retrieves the amount withdrawn from the stream, denoted in units of the token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getWithdrawnAmount(uint256 streamId) external view returns (uint128 withdrawnAmount);

    /// @notice Retrieves a flag indicating whether the provided address is a contract allowed to hook to Sablier
    /// when a stream is canceled or when tokens are withdrawn.
    /// @dev See {ISablierLockupRecipient} for more information.
    function isAllowedToHook(address recipient) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the stream can be canceled. When the stream is cold, this
    /// flag is always `false`.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isCancelable(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the stream is depleted.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isDepleted(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the stream exists.
    /// @dev Does not revert if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isStream(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the stream NFT can be transferred.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isTransferable(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves the address of the ERC-20 interface of the native token, if it exists.
    /// @dev The native tokens on some chains have a dual interface as ERC-20. For example, on Polygon the $POL token
    /// is the native token and has an ERC-20 version at 0x0000000000000000000000000000000000001010. This means
    /// that `address(this).balance` returns the same value as `balanceOf(address(this))`. To avoid any unintended
    /// behavior, these tokens cannot be used in Sablier. As an alternative, users can use the Wrapped version of the
    /// token, i.e. WMATIC, which is a standard ERC-20 token.
    function nativeToken() external view returns (address);

    /// @notice Counter for stream IDs, used in the create functions.
    function nextStreamId() external view returns (uint256);

    /// @notice Contract that generates the non-fungible token URI.
    function nftDescriptor() external view returns (ILockupNFTDescriptor);

    /// @notice Retrieves a flag indicating whether the stream was canceled.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function wasCanceled(uint256 streamId) external view returns (bool result);
}
