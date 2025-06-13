// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud60x18, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup, LockupLinear } from "@sablier/lockup/src/types/DataTypes.sol";

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

    /// @inheritdoc ISablierMerkleLL
    uint40 public immutable override VESTING_CLIFF_DURATION;

    /// @inheritdoc ISablierMerkleLL
    UD60x18 public immutable override VESTING_CLIFF_UNLOCK_PERCENTAGE;

    /// @inheritdoc ISablierMerkleLL
    uint40 public immutable override VESTING_START_TIME;

    /// @inheritdoc ISablierMerkleLL
    UD60x18 public immutable override VESTING_START_UNLOCK_PERCENTAGE;

    /// @inheritdoc ISablierMerkleLL
    uint40 public immutable override VESTING_TOTAL_DURATION;

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
            params.campaignStartTime,
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
        // Effect: set the immutable variables.
        VESTING_CLIFF_DURATION = params.cliffDuration;
        VESTING_CLIFF_UNLOCK_PERCENTAGE = params.cliffUnlockPercentage;
        VESTING_START_TIME = params.vestingStartTime;
        VESTING_START_UNLOCK_PERCENTAGE = params.startUnlockPercentage;
        VESTING_TOTAL_DURATION = params.totalDuration;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    function claim(
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: recipient, amount: amount });
    }

    /// @inheritdoc ISablierMerkleLL
    function claimTo(
        uint256 index,
        address to,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
        notZeroAddress(to)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Effect and Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount });
    }

    /// @inheritdoc ISablierMerkleLL
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable
        override
        notZeroAddress(to)
    {
        // Check: the signature is valid and the recovered signer matches the recipient.
        _checkSignature(index, recipient, to, amount, signature);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim(index, recipient, to, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by creating the stream or transferring the tokens directly and emitting
    /// an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 amount) private {
        // Calculate the timestamps.
        Lockup.Timestamps memory timestamps;
        // Zero is a sentinel value for `block.timestamp`.
        if (VESTING_START_TIME == 0) {
            timestamps.start = uint40(block.timestamp);
        } else {
            timestamps.start = VESTING_START_TIME;
        }
        timestamps.end = timestamps.start + VESTING_TOTAL_DURATION;

        // If the end time is not in the future, transfer the amount directly to the `to` address..
        if (timestamps.end <= block.timestamp) {
            // Interaction: transfer the tokens to the `to` address.
            TOKEN.safeTransfer(to, amount);

            // Log the claim.
            emit Claim(index, recipient, amount, to);
        }
        // Otherwise, create the Lockup stream to start the vesting.
        else {
            // Calculate cliff time.
            uint40 cliffTime;
            if (VESTING_CLIFF_DURATION > 0) {
                cliffTime = timestamps.start + VESTING_CLIFF_DURATION;
            }

            // Calculate the unlock amounts based on the percentages.
            LockupLinear.UnlockAmounts memory unlockAmounts;
            unlockAmounts.start = ud60x18(amount).mul(VESTING_START_UNLOCK_PERCENTAGE).intoUint128();
            unlockAmounts.cliff = ud60x18(amount).mul(VESTING_CLIFF_UNLOCK_PERCENTAGE).intoUint128();

            // Safe Interaction: create the stream with `to` as the stream recipient.
            uint256 streamId = SABLIER_LOCKUP.createWithTimestampsLL(
                Lockup.CreateWithTimestamps({
                    sender: admin,
                    recipient: to,
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
            emit Claim(index, recipient, amount, streamId, to);
        }
    }
}
