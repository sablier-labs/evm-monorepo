// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud60x18, UD60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup } from "@sablier/lockup/src/types/Lockup.sol";
import { LockupLinear } from "@sablier/lockup/src/types/LockupLinear.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { SablierMerkleLockup } from "./abstracts/SablierMerkleLockup.sol";
import { SablierMerkleSignature } from "./abstracts/SablierMerkleSignature.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { ClaimType, MerkleBase } from "./types/MerkleBase.sol";
import { MerkleLockup } from "./types/MerkleLockup.sol";
import { MerkleLL } from "./types/MerkleLL.sol";

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
    ISablierMerkleLL, // 4 inherited components
    SablierMerkleSignature, // 5 inherited components
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
    uint40 public immutable override VESTING_GRANULARITY;

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
        MerkleLL.ConstructorParams memory campaignParams,
        address campaignCreator,
        address comptroller
    )
        SablierMerkleBase(MerkleBase.ConstructorParams({
                campaignCreator: campaignCreator,
                campaignName: campaignParams.campaignName,
                campaignStartTime: campaignParams.campaignStartTime,
                claimType: campaignParams.claimType,
                comptroller: comptroller,
                expiration: campaignParams.expiration,
                initialAdmin: campaignParams.initialAdmin,
                ipfsCID: campaignParams.ipfsCID,
                merkleRoot: campaignParams.merkleRoot,
                token: campaignParams.token
            }))
        SablierMerkleLockup(MerkleLockup.ConstructorParams({
                cancelable: campaignParams.cancelable,
                lockup: campaignParams.lockup,
                shape: campaignParams.shape,
                transferable: campaignParams.transferable
            }))
    {
        // Effect: set the immutable variables.
        VESTING_CLIFF_DURATION = campaignParams.cliffDuration;
        VESTING_CLIFF_UNLOCK_PERCENTAGE = campaignParams.cliffUnlockPercentage;
        VESTING_GRANULARITY = campaignParams.granularity;
        VESTING_START_TIME = campaignParams.vestingStartTime;
        VESTING_START_UNLOCK_PERCENTAGE = campaignParams.startUnlockPercentage;
        VESTING_TOTAL_DURATION = campaignParams.totalDuration;
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
        revertIfNot(ClaimType.DEFAULT)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: recipient, amount: amount, viaSig: false });
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
        revertIfNot(ClaimType.DEFAULT)
        notZeroAddress(to)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Effect and Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleLL
    function claimViaAttestation(
        uint256 index,
        address to,
        uint128 amount,
        uint40 expireAt,
        bytes32[] calldata merkleProof,
        bytes calldata attestation
    )
        external
        payable
        override
        revertIfNot(ClaimType.ATTEST)
        notZeroAddress(to)
    {
        // Check: the attestation signature is valid and the recovered signer matches the attestor.
        _verifyAttestationSignature(msg.sender, expireAt, attestation);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Effect and Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleLL
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        uint40 validFrom,
        bytes32[] calldata merkleProof,
        bytes calldata signature
    )
        external
        payable
        override
        revertIfNot(ClaimType.DEFAULT)
        notZeroAddress(to)
    {
        // Check: the signature is valid and the recovered signer matches the recipient.
        _verifyClaimSignature(index, recipient, to, amount, validFrom, signature);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: to, amount: amount, viaSig: true });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by creating the stream or transferring the tokens directly and emitting
    /// an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 amount, bool viaSig) private {
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

            // Emit claim event.
            emit ClaimLLWithTransfer(index, recipient, amount, to, viaSig);
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
                VESTING_GRANULARITY,
                cliffTime
            );

            // Effect: push the stream ID into the claimed streams array.
            _claimedStreams[recipient].push(streamId);

            // Emit claim event.
            emit ClaimLLWithVesting(index, recipient, amount, streamId, to, viaSig);
        }
    }
}
