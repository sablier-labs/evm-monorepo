// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup, LockupLinear } from "@sablier/lockup/src/types/DataTypes.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { SablierMerkleLockup } from "./abstracts/SablierMerkleLockup.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { MerkleLL } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗     ██╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║     ██║
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║     ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║     ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ███████╗███████╗
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚══════╝

 */

/// @title SablierMerkleLL
/// @notice See the documentation in {ISablierMerkleLL}.
contract SablierMerkleLL is
    ISablierMerkleLL, // 3 inherited components
    SablierMerkleLockup // 5 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation in {ISablierMerkleLL.getSchedule}.
    MerkleLL.Schedule private _schedule;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleLL.ConstructorParams memory params,
        address campaignCreator
    )
        SablierMerkleLockup(
            campaignCreator,
            params.campaignName,
            params.cancelable,
            params.lockup,
            params.expiration,
            params.initialAdmin,
            params.ipfsCID,
            params.merkleRoot,
            params.shape,
            params.token,
            params.transferable
        )
    {
        _schedule = params.schedule;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    function getSchedule() external view override returns (MerkleLL.Schedule memory) {
        return _schedule;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        // Load schedule from storage into memory.
        MerkleLL.Schedule memory schedule = _schedule;

        // Calculate the timestamps.
        Lockup.Timestamps memory timestamps;
        // Zero is a sentinel value for `block.timestamp`.
        if (schedule.startTime == 0) {
            timestamps.start = uint40(block.timestamp);
        } else {
            timestamps.start = schedule.startTime;
        }
        timestamps.end = timestamps.start + schedule.totalDuration;

        // If the end time is not in the future, transfer the amount directly to the recipient.
        if (timestamps.end <= block.timestamp) {
            // Interaction: transfer the tokens to the recipient.
            TOKEN.safeTransfer(recipient, amount);

            // Log the claim.
            emit Claim(index, recipient, amount);
        }
        // Otherwise, create the Lockup stream to start the vesting.
        else {
            // Calculate cliff time.
            uint40 cliffTime;
            if (schedule.cliffDuration > 0) {
                cliffTime = timestamps.start + schedule.cliffDuration;
            }

            // Calculate the unlock amounts based on the percentages.
            LockupLinear.UnlockAmounts memory unlockAmounts;
            unlockAmounts.start = ud60x18(amount).mul(schedule.startPercentage.intoUD60x18()).intoUint128();
            unlockAmounts.cliff = ud60x18(amount).mul(schedule.cliffPercentage.intoUD60x18()).intoUint128();

            // Safe Interaction: create the stream.
            uint256 streamId = SABLIER_LOCKUP.createWithTimestampsLL(
                Lockup.CreateWithTimestamps({
                    sender: admin,
                    recipient: recipient,
                    depositAmount: amount,
                    token: TOKEN,
                    cancelable: STREAM_CANCELABLE,
                    transferable: STREAM_TRANSFERABLE,
                    timestamps: timestamps,
                    shape: streamShape
                }),
                unlockAmounts,
                cliffTime
            );

            // Effect: push the stream ID into the claimed streams array.
            _claimedStreams[recipient].push(streamId);

            // Log the claim.
            emit Claim(index, recipient, amount, streamId);
        }
    }
}
