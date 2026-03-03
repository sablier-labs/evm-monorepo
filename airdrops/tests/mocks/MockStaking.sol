// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";

/// @notice A mock staking contract for testing MerkleExecute campaigns.
contract MockStaking {
    using SafeERC20 for IERC20;
    IERC20 public token;

    constructor(IERC20 token_) {
        token = token_;
    }

    function stake(uint128 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function revertingFunction(uint128) external pure {
        revert("Shall not pass!");
    }
}

/// @notice A mock staking contract that transfers less than the amount requested.
contract MockStakingPartialTransfer {
    using SafeERC20 for IERC20;
    IERC20 public token;

    constructor(IERC20 token_) {
        token = token_;
    }

    function stake(uint128 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount / 2);
    }
}

/// @notice A malicious staking contract that attempts to re-enter the MerkleExecute campaign.
contract MockStakingReentrant {
    IERC20 public token;

    constructor(IERC20 token_) {
        token = token_;
    }

    /// @dev This function attempts to re-enter the MerkleExecute campaign when called.
    function stake(
        uint256 index,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata selectorArguments
    )
        external
    {
        // Attempt reentrancy attack by calling claimAndExecute again.
        ISablierMerkleExecute(msg.sender).claimAndExecute(index, amount, merkleProof, selectorArguments);
    }
}

/// @notice A mock staking contract that always reverts on stake attempts.
contract MockStakingRevert {
    function stake(uint128) external pure {
        revert("Shall not pass!");
    }
}

