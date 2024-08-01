// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierLockupDynamic } from "../../core/interfaces/ISablierLockupDynamic.sol";
import { ISablierLockupLinear } from "../../core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "../../core/interfaces/ISablierLockupTranched.sol";

import { BatchLockup } from "../types/DataTypes.sol";

/// @title ISablierBatchLockup
/// @notice Helper to batch create Lockup streams.
interface ISablierBatchLockup {
    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of Lockup Dynamic streams using `createWithDurations`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupDynamic.createWithDurations} must be met for each stream.
    ///
    /// @param lockupDynamic The address of the {SablierLockupDynamic} contract.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockupDynamic.createWithDurations}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLD(
        ISablierLockupDynamic lockupDynamic,
        IERC20 asset,
        BatchLockup.CreateWithDurationsLD[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of Lockup Dynamic streams using `createWithTimestamps`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupDynamic.createWithTimestamps} must be met for each stream.
    ///
    /// @param lockupDynamic The address of the {SablierLockupDynamic} contract.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockupDynamic.createWithTimestamps}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLD(
        ISablierLockupDynamic lockupDynamic,
        IERC20 asset,
        BatchLockup.CreateWithTimestampsLD[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of LockupLinear streams using `createWithDurations`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupLinear.createWithDurations} must be met for each stream.
    ///
    /// @param lockupLinear The address of the {SablierLockupLinear} contract.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockupLinear.createWithDurations}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLL(
        ISablierLockupLinear lockupLinear,
        IERC20 asset,
        BatchLockup.CreateWithDurationsLL[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of LockupLinear streams using `createWithTimestamps`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupLinear.createWithTimestamps} must be met for each stream.
    ///
    /// @param lockupLinear The address of the {SablierLockupLinear} contract.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockupLinear.createWithTimestamps}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLL(
        ISablierLockupLinear lockupLinear,
        IERC20 asset,
        BatchLockup.CreateWithTimestampsLL[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /*//////////////////////////////////////////////////////////////////////////
                              SABLIER-LOCKUP-TRANCHED
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of LockupTranched streams using `createWithDurations`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupTranched.createWithDurations} must be met for each stream.
    ///
    /// @param lockupTranched The address of the {SablierLockupTranched} contract.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockupTranched.createWithDurations}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLT(
        ISablierLockupTranched lockupTranched,
        IERC20 asset,
        BatchLockup.CreateWithDurationsLT[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of LockupTranched streams using `createWithTimestamps`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupTranched.createWithTimestamps} must be met for each stream.
    ///
    /// @param lockupTranched The address of the {SablierLockupTranched} contract.
    /// @param asset The contract address of the ERC-20 asset to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {SablierLockupTranched.createWithTimestamps}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLT(
        ISablierLockupTranched lockupTranched,
        IERC20 asset,
        BatchLockup.CreateWithTimestampsLT[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);
}
