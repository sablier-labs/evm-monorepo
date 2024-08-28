// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

import { ISablierLockupLinear } from "../core/interfaces/ISablierLockupLinear.sol";
import { Broker, LockupLinear } from "../core/types/DataTypes.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { MerkleBase, MerkleLL } from "./types/DataTypes.sol";

/// @title SablierMerkleLL
/// @notice See the documentation in {ISablierMerkleLL}.
contract SablierMerkleLL is
    ISablierMerkleLL, // 2 inherited components
    SablierMerkleBase // 4 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    bool public immutable override CANCELABLE;

    /// @inheritdoc ISablierMerkleLL
    ISablierLockupLinear public immutable override LOCKUP_LINEAR;

    /// @inheritdoc ISablierMerkleLL
    bool public immutable override TRANSFERABLE;

    /// @inheritdoc ISablierMerkleLL
    MerkleLL.Schedule public override schedule;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockupLinear lockupLinear,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule memory schedule_
    )
        SablierMerkleBase(baseParams)
    {
        CANCELABLE = cancelable;
        LOCKUP_LINEAR = lockupLinear;
        TRANSFERABLE = transferable;
        schedule = schedule_;

        // Max approve the Lockup contract to spend funds from the MerkleLL contract.
        ASSET.forceApprove(address(LOCKUP_LINEAR), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        // Calculate the timestamps for the stream.
        LockupLinear.Timestamps memory timestamps;
        if (schedule.startTime == 0) {
            timestamps.start = uint40(block.timestamp);
        } else {
            timestamps.start = schedule.startTime;
        }

        // It is safe to use unchecked arithmetic because the `createWithTimestamps` function in the Lockup contract
        // will nonetheless make the relevant checks.
        unchecked {
            if (schedule.cliffDuration > 0) {
                timestamps.cliff = timestamps.start + schedule.cliffDuration;
            }
            timestamps.end = timestamps.start + schedule.totalDuration;
        }

        // Interaction: create the stream via {SablierLockupLinear}.
        uint256 streamId = LOCKUP_LINEAR.createWithTimestamps(
            LockupLinear.CreateWithTimestamps({
                sender: admin,
                recipient: recipient,
                totalAmount: amount,
                asset: ASSET,
                cancelable: CANCELABLE,
                transferable: TRANSFERABLE,
                timestamps: timestamps,
                broker: Broker({ account: address(0), fee: ud(0) })
            })
        );

        // Log the claim.
        emit Claim(index, recipient, amount, streamId);
    }
}
