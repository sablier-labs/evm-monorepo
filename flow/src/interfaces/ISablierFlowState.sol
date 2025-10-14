// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

import { Flow } from "./../types/DataTypes.sol";
import { IFlowNFTDescriptor } from "./IFlowNFTDescriptor.sol";

/// @title ISablierFlowState
/// @notice Contract with state variables (storage and constants) for the {SablierFlow} contract, their respective
/// getters and helpful modifiers.
interface ISablierFlowState {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the aggregate amount across all streams, denoted in units of the token's decimals.
    /// @dev If tokens are directly transferred to the contract without using the stream creation functions, the
    /// ERC-20 balance may be greater than the aggregate amount.
    /// @param token The ERC-20 token for the query.
    function aggregateAmount(IERC20 token) external view returns (uint256);

    /// @notice Retrieves the balance of the stream, i.e. the total deposited amounts subtracted by the total withdrawn
    /// amounts, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getBalance(uint256 streamId) external view returns (uint128 balance);

    /// @notice Retrieves the rate per second of the stream, denoted as a fixed-point number where 1e18 is 1 token
    /// per second.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The ID of the stream to make the query for.
    function getRatePerSecond(uint256 streamId) external view returns (UD21x18 ratePerSecond);

    /// @notice Retrieves the stream's sender.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Retrieves the snapshot debt of the stream, denoted as a fixed-point number where 1e18 is 1 token.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getSnapshotDebtScaled(uint256 streamId) external view returns (uint256 snapshotDebtScaled);

    /// @notice Retrieves the snapshot time of the stream, which is a Unix timestamp.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The ID of the stream to make the query for.
    function getSnapshotTime(uint256 streamId) external view returns (uint40 snapshotTime);

    /// @notice Retrieves the stream entity.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getStream(uint256 streamId) external view returns (Flow.Stream memory stream);

    /// @notice Retrieves the token of the stream.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The ID of the stream to make the query for.
    function getToken(uint256 streamId) external view returns (IERC20 token);

    /// @notice Retrieves the token decimals of the stream.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The ID of the stream to make the query for.
    function getTokenDecimals(uint256 streamId) external view returns (uint8 tokenDecimals);

    /// @notice Retrieves a flag indicating whether the stream exists.
    /// @dev Does not revert if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isStream(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the stream NFT is transferable.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isTransferable(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves a flag indicating whether the stream is voided.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isVoided(uint256 streamId) external view returns (bool result);

    /// @notice Retrieves the address of the ERC-20 interface of the native token, if it exists.
    /// @dev The native tokens on some chains have a dual interface as ERC-20. For example, on Polygon the $POL token
    /// is the native token and has an ERC-20 version at 0x0000000000000000000000000000000000001010. This means
    /// that `address(this).balance` returns the same value as `balanceOf(address(this))`. To avoid any unintended
    /// behavior, these tokens cannot be used in Sablier. As an alternative, users can use the Wrapped version of the
    /// token, i.e. WMATIC, which is a standard ERC-20 token.
    function nativeToken() external view returns (address);

    /// @notice Counter for stream ids.
    /// @return The next stream ID.
    function nextStreamId() external view returns (uint256);

    /// @notice Contract that generates the non-fungible token URI.
    function nftDescriptor() external view returns (IFlowNFTDescriptor);
}
