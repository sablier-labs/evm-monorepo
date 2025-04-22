// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { IRoleAdminable } from "@sablier/evm-utils/src/interfaces/IRoleAdminable.sol";

import { Flow } from "./../types/DataTypes.sol";
import { IFlowNFTDescriptor } from "./IFlowNFTDescriptor.sol";

/// @title ISablierFlowBase
/// @notice Base contract that includes state variables (storage and constants) for the {SablierFlow} contract,
/// their respective getters, helpful modifiers, and helper functions.
/// @dev This contract also includes admin control functions.
interface ISablierFlowBase is
    IRoleAdminable, // 1 inherited components
    IERC4906, // 2 inherited components
    IERC721Metadata // 2 inherited components
{
    /// @notice Emitted when the accrued fees are collected.
    /// @param admin The address of the current contract admin.
    /// @param feeRecipient The address where the fees will be collected.
    /// @param feeAmount The amount of collected fees.
    event CollectFees(address indexed admin, address indexed feeRecipient, uint256 feeAmount);

    /// @notice Emitted when the contract admin recovers the surplus amount of token.
    /// @param admin The address of the contract admin.
    /// @param token The address of the ERC-20 token the surplus amount has been recovered for.
    /// @param to The address the surplus amount has been sent to.
    /// @param surplus The amount of surplus tokens recovered.
    event Recover(address indexed admin, IERC20 indexed token, address to, uint256 surplus);

    /// @notice Emitted when the native token address is set by the admin.
    event SetNativeToken(address indexed admin, address nativeToken);

    /// @notice Emitted when the contract admin sets a new NFT descriptor contract.
    /// @param admin The address of the contract admin.
    /// @param oldNFTDescriptor The address of the old NFT descriptor contract.
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    event SetNFTDescriptor(
        address indexed admin, IFlowNFTDescriptor oldNFTDescriptor, IFlowNFTDescriptor newNFTDescriptor
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
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

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Collects the accrued fees. If `feeRecipient` is a contract, it must be able to receive native tokens,
    /// e.g., ETH for Ethereum Mainnet.
    ///
    /// @dev Emits a {CollectFees} event.
    ///
    /// Requirements:
    /// - If `msg.sender` has neither the {IRoleAdminable.FEE_COLLECTOR_ROLE} role nor is the contract admin, then
    /// `feeRecipient` must be the admin address.
    ///
    /// @param feeRecipient The address where the fees will be collected.
    function collectFees(address feeRecipient) external;

    /// @notice Recover the surplus amount of tokens.
    ///
    /// @dev Emits a {Recover} event.
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

    /// @notice Sets the native token address. Once set, it cannot be changed.
    /// @dev For more information, see the documentation for {nativeToken}.
    ///
    /// Emits a {SetNativeToken} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
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
    /// - `msg.sender` must be the contract admin.
    ///
    /// @param newNFTDescriptor The address of the new NFT descriptor contract.
    function setNFTDescriptor(IFlowNFTDescriptor newNFTDescriptor) external;
}
