// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title ILidoWithdrawalQueue
/// @notice Minimal interface for Lido's WithdrawalQueueERC721 contract.
/// @dev Used as a fallback unstaking path when the Curve pool is unavailable.
interface ILidoWithdrawalQueue {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Maximum amount of stETH that can be withdrawn in a single request.
    function MAX_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    /// @notice Minimum amount of stETH that can be withdrawn in a single request.
    function MIN_STETH_WITHDRAWAL_AMOUNT() external view returns (uint256);

    /// @notice Finds the list of hints for the given `_requestIds` searching among the checkpoints with indices in the
    /// range  `[_firstIndex, _lastIndex]`.
    /// @dev
    /// - Array of request ids should be sorted.
    /// - `_firstIndex` should be greater than 0, because checkpoint list is 1-based array.
    /// - `_lastIndex` should be less than or equal to `getLastCheckpointIndex()`.
    /// @param _requestIds ids of the requests sorted in the ascending order to get hints for.
    /// @param _firstIndex left boundary of the search range. Should be greater than 0.
    /// @param _lastIndex right boundary of the search range. Should be less than or equal to
    /// `getLastCheckpointIndex()`.
    /// @return hintIds array of hints used to find required checkpoint for the request.
    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256 _firstIndex,
        uint256 _lastIndex
    )
        external
        view
        returns (uint256[] memory hintIds);

    /// @notice length of the checkpoint array. Last possible value for the hint.
    function getLastCheckpointIndex() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Claim a batch of withdrawal requests if they are finalized sending locked ether to the owner.
    /// @param _requestIds array of request ids to claim.
    /// @param _hints checkpoint hint for each id. Can be obtained with `findCheckpointHints()`
    /// @dev Reverts if any of the following conditions are met:
    ///  - `requestIds` and `hints` arrays length differs.
    ///  - Any `requestId` or `hint` in arguments are not valid.
    ///  - Any request is not finalized or already claimed.
    ///  - `msg.sender` is not an owner of the requests.
    function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata _hints) external;

    /// @notice Request the batch of stETH for withdrawal. Approvals for the passed amounts should be done before.
    /// @param _amounts an array of stETH amount values. The standalone withdrawal request will be created for each item
    /// in the passed list.
    /// @param _owner address that will be able to manage the created requests. If `address(0)` is passed, `msg.sender`
    /// will be used as owner.
    /// @return requestIds an array of the created withdrawal request ids.
    function requestWithdrawals(
        uint256[] calldata _amounts,
        address _owner
    )
        external
        returns (uint256[] memory requestIds);
}
