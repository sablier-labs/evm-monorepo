// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockup } from "../interfaces/ISablierLockup.sol";

import { BatchLockup } from "../types/DataTypes.sol";

/// @title ISablierBatchLockup
/// @notice Helper to batch create Lockup streams.
interface ISablierBatchLockup {
    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of Lockup Dynamic streams using `createWithDurationsLD`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockup.createWithDurationsLD} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockup.createWithDurationsLD}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLD(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLD[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of Lockup Dynamic streams using `createWithTimestampsLD`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockup.createWithTimestampsLD} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockup.createWithTimestampsLD}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLD(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLD[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of Lockup Linear streams using `createWithDurationsLL`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockup.createWithDurationsLL} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockup.createWithDurationsLL}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLL(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLL[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of Lockup Linear streams using `createWithTimestampsLL`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockup.createWithTimestampsLL} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockup.createWithTimestampsLL}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLL(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLL[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-LOCKUP-TRANCHED
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of Lockup Tranched streams using `createWithDurationsLT`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockup.createWithDurationsLT} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockup.createWithDurationsLT}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLT(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLT[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of Lockup Tranched streams using `createWithTimestampsLT`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockup.createWithTimestampsLT} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockup.createWithTimestampsLT}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLT(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLT[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);
}
