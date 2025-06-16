// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BatchLockup } from "../types/BatchLockup.sol";
import { ISablierLockup } from "./ISablierLockup.sol";

/// @title ISablierBatchLockup
/// @notice Helper to batch create Lockup streams.
interface ISablierBatchLockup {
    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a batch of LD streams using `createWithDurationsLD`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupDynamic.createWithDurationsLD} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {ISablierLockupDynamic.createWithDurationsLD}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLD(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLD[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of LD streams using `createWithTimestampsLD`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupDynamic.createWithTimestampsLD} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {ISablierLockupDynamic.createWithTimestampsLD}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLD(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLD[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of LL streams using `createWithDurationsLL`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupLinear.createWithDurationsLL} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {ISablierLockupLinear.createWithDurationsLL}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLL(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLL[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of LL streams using `createWithTimestampsLL`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupLinear.createWithTimestampsLL} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {ISablierLockupLinear.createWithTimestampsLL}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLL(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLL[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of LT streams using `createWithDurationsLT`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupTranched.createWithDurationsLT} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {ISablierLockupTranched.createWithDurationsLT}.
    /// @return streamIds The ids of the newly created streams.
    function createWithDurationsLT(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithDurationsLT[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);

    /// @notice Creates a batch of LT streams using `createWithTimestampsLT`.
    ///
    /// @dev Requirements:
    /// - There must be at least one element in `batch`.
    /// - All requirements from {ISablierLockupTranched.createWithTimestampsLT} must be met for each stream.
    ///
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param token The contract address of the ERC-20 token to be distributed.
    /// @param batch An array of structs, each encapsulating a subset of the parameters of
    /// {ISablierLockupTranched.createWithTimestampsLT}.
    /// @return streamIds The ids of the newly created streams.
    function createWithTimestampsLT(
        ISablierLockup lockup,
        IERC20 token,
        BatchLockup.CreateWithTimestampsLT[] calldata batch
    )
        external
        returns (uint256[] memory streamIds);
}
