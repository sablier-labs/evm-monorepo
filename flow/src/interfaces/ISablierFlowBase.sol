// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Flow } from "./../types/DataTypes.sol";
import { IAdminable } from "./IAdminable.sol";
import { IFlowNFTDescriptor } from "./IFlowNFTDescriptor.sol";

/// @title ISablierFlowBase
/// @notice Base contract that includes state variables (storage and constants) for the {SablierFlow} contract,
/// their respective getters, helpful modifiers, and helper functions.
/// @dev This contract also includes admin control functions.
interface ISablierFlowBase is
    IERC4906, // 2 inherited components
    IERC721Metadata, // 2 inherited components
    IAdminable // 0 inherited components
{
    /// @notice Emitted when the contract admin collects protocol revenue accrued.
    /// @param admin The address of the contract admin.
    /// @param token The address of the ERC-20 token the protocol revenue has been collected for.
    /// @param to The address the protocol revenue has been sent to.
    /// @param revenue The amount of protocol revenue collected.
    event CollectProtocolRevenue(address indexed admin, IERC20 indexed token, address to, uint128 revenue);

    /// @notice Emitted when the contract admin recovers the surplus amount of token.
    /// @param admin The address of the contract admin.
    /// @param token The address of the ERC-20 token the surplus amount has been recovered for.
    /// @param to The address the surplus amount has been sent to.
    /// @param surplus The amount of surplus tokens recovered.
    event Recover(address indexed admin, IERC20 indexed token, address to, uint256 surplus);

    /// @notice Emitted when the contract admin sets a new NFT descriptor contract.
    /// @param admin The address of the contract admin.
    /// @param oldNFTDescriptor The address of the old NFT descriptor contract.
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    event SetNFTDescriptor(
        address indexed admin, IFlowNFTDescriptor oldNFTDescriptor, IFlowNFTDescriptor newNFTDescriptor
    );

    /// @notice Emitted when the contract admin sets a new protocol fee for the provided ERC-20 token.
    /// @param admin The address of the contract admin.
    /// @param token The address of the ERC-20 token the new protocol fee has been set for.
    /// @param oldProtocolFee The old protocol fee, denoted as a fixed-point percentage.
    /// @param newProtocolFee The new protocol fee, denoted as a fixed-point percentage.
    event SetProtocolFee(address indexed admin, IERC20 indexed token, UD60x18 oldProtocolFee, UD60x18 newProtocolFee);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the maximum fee that can be charged by the broker and the protocol, denoted as a fixed-point
    /// percentage where 1e18 is 100%.
    /// @dev This value is hard coded as a constant.
    function MAX_FEE() external view returns (UD60x18 fee);

    /// @notice Retrieves the sum of balances of all streams.
    /// @param token The ERC-20 token for the query.
    function aggregateBalance(IERC20 token) external view returns (uint256);

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

    /// @notice Retrieves the stream's recipient.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getRecipient(uint256 streamId) external view returns (address recipient);

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

    /// @notice Returns whether a stream is paused.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function isPaused(uint256 streamId) external view returns (bool result);

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

    /// @notice Counter for stream ids.
    /// @return The next stream ID.
    function nextStreamId() external view returns (uint256);

    /// @notice Contract that generates the non-fungible token URI.
    function nftDescriptor() external view returns (IFlowNFTDescriptor);

    /// @notice Protocol fee for the provided ERC-20 token, denoted as a fixed-point percentage where 1e18 is 100%.
    function protocolFee(IERC20 token) external view returns (UD60x18);

    /// @notice Protocol revenue accrued for the provided ERC-20 token, denoted in token's decimals.
    function protocolRevenue(IERC20 token) external view returns (uint128);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Collect the protocol revenue accrued for the provided ERC-20 token.
    ///
    /// @dev Emits {CollectProtocolRevenue} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    /// - The accrued protocol revenue must be greater than zero.
    ///
    /// @param token The contract address of the ERC-20 token for which to claim protocol revenue.
    /// @param to The address to send the protocol revenue.
    function collectProtocolRevenue(IERC20 token, address to) external;

    /// @notice Recover the surplus amount of tokens.
    ///
    /// @dev Emits {Recover} event.
    ///
    /// Notes:
    /// - The surplus amount is defined as the difference between the total balance of the contract for the provided
    /// ERC-20 token and the sum of balances of all streams created using the same ERC-20 token.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    /// - The surplus amount must be greater than zero.
    ///
    /// @param token The contract address of the ERC-20 token to recover for.
    /// @param to The address to send the surplus amount.
    function recover(IERC20 token, address to) external;

    /// @notice Sets a new NFT descriptor contract, which produces the URI describing the Sablier stream NFTs.
    ///
    /// @dev Emits {SetNFTDescriptor} and {BatchMetadataUpdate} events.
    ///
    /// Notes:
    /// - Does not revert if the NFT descriptor is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    function setNFTDescriptor(IFlowNFTDescriptor newNFTDescriptor) external;

    /// @notice Sets a new protocol fee that will be charged on all the withdrawals from streams created with the
    /// provided ERC-20 token.
    ///
    /// @dev Emits {SetProtocolFee} and {BatchMetadataUpdate} events.
    ///
    /// Notes:
    /// - Does not revert if the fee is the same.
    /// - It can be zero.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    /// - `newProtocolFee` must not be greater than `MAX_FEE`.
    ///
    /// @param token The contract address of the ERC-20 token to update the fee for.
    /// @param newProtocolFee The new protocol fee, denoted as a fixed-point percentage where 1e18 is 100%.
    function setProtocolFee(IERC20 token, UD60x18 newProtocolFee) external;
}
