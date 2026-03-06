// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ILidoWithdrawalQueue } from "src/interfaces/external/ILidoWithdrawalQueue.sol";

/// @notice Mock Lido WithdrawalQueueERC721 for testing.
contract MockLidoWithdrawalQueue is ILidoWithdrawalQueue {
    uint256 public constant MAX_STETH_WITHDRAWAL_AMOUNT = 1000 ether;
    uint256 public constant LAST_CHECKPOINT_INDEX = 1;

    uint256 private _nextRequestId = 1;

    /// @dev Maps request ID to the stETH amount deposited.
    mapping(uint256 requestId => uint256 amount) private _requestAmounts;

    function requestWithdrawals(
        uint256[] calldata _amounts,
        address
    )
        external
        override
        returns (uint256[] memory requestIds)
    {
        requestIds = new uint256[](_amounts.length);
        for (uint256 i; i < _amounts.length; ++i) {
            requestIds[i] = _nextRequestId++;
            _requestAmounts[requestIds[i]] = _amounts[i];
        }
    }

    function claimWithdrawals(uint256[] calldata _requestIds, uint256[] calldata) external override {
        uint256 totalEth;
        for (uint256 i; i < _requestIds.length; ++i) {
            totalEth += _requestAmounts[_requestIds[i]];
            delete _requestAmounts[_requestIds[i]];
        }
        (bool success,) = msg.sender.call{ value: totalEth }("");
        require(success, "ETH transfer failed");
    }

    function findCheckpointHints(
        uint256[] calldata _requestIds,
        uint256,
        uint256
    )
        external
        pure
        override
        returns (uint256[] memory hintIds)
    {
        hintIds = new uint256[](_requestIds.length);
        for (uint256 i; i < _requestIds.length; ++i) {
            hintIds[i] = 1;
        }
    }

    function getLastCheckpointIndex() external pure override returns (uint256) {
        return LAST_CHECKPOINT_INDEX;
    }

    receive() external payable { }
}
