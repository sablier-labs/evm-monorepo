// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Flow } from "./../types/DataTypes.sol";
import { ISablierFlowNFTDescriptor } from "./ISablierFlowNFTDescriptor.sol";

/// @title ISablierFlowState
/// @notice State variables, storage and constants, for the {SablierFlow} contract, and their respective getters.
/// @dev This contract also includes helpful modifiers and helper functions.
interface ISablierFlowState is
    IERC721Metadata // 2 inherited components
{
    /// @notice Emitted when the admin sets a new NFT descriptor contract.
    /// @param admin The address of the current contract admin.
    /// @param oldNFTDescriptor The address of the old NFT descriptor contract.
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    event SetNFTDescriptor(
        address indexed admin, ISablierFlowNFTDescriptor oldNFTDescriptor, ISablierFlowNFTDescriptor newNFTDescriptor
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the maximum broker fee that can be charged by the broker, denoted as a fixed-point number
    /// where 1e18 is 100%.
    /// @dev This value is hard coded as a constant.
    function MAX_BROKER_FEE() external view returns (UD60x18 fee);

    /// @notice Retrieves the balance of the stream, i.e. the total deposited amounts subtracted by the total withdrawn
    /// amounts, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getBalance(uint256 streamId) external view returns (uint128 balance);

    /// @notice Retrieves the rate per second of the stream, denoted in 18 decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The ID of the stream to make the query for.
    function getRatePerSecond(uint256 streamId) external view returns (uint128 ratePerSecond);

    /// @notice Retrieves the stream's recipient.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getRecipient(uint256 streamId) external view returns (address recipient);

    /// @notice Retrieves the stream's sender.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getSender(uint256 streamId) external view returns (address sender);

    /// @notice Retrieves the snapshot debt of the stream, denoted in token's decimals.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The stream ID for the query.
    function getSnapshotDebt(uint256 streamId) external view returns (uint128 snapshotDebt);

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

    /// @notice Retrieves a flag indicating whether the stream is paused.
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

    /// @notice Counter for stream ids.
    /// @return The next stream ID.
    function nextStreamId() external view returns (uint256);

    /// @notice Contract that generates the non-fungible token URI.
    function nftDescriptor() external view returns (ISablierFlowNFTDescriptor);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets a new NFT descriptor contract, which produces the URI describing the Sablier stream NFTs.
    ///
    /// @dev Emits a {SetNFTDescriptor} and {BatchMetadataUpdate} event.
    ///
    /// Notes:
    /// - Does not revert if the NFT descriptor is the same.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    function setNFTDescriptor(ISablierFlowNFTDescriptor newNFTDescriptor) external;
}
