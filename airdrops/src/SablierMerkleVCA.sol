// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { SablierMerkleSignature } from "./abstracts/SablierMerkleSignature.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { Errors } from "./libraries/Errors.sol";
import { ClaimType, MerkleBase } from "./types/MerkleBase.sol";
import { MerkleVCA } from "./types/MerkleVCA.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗   ██╗ ██████╗ █████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║   ██║██╔════╝██╔══██╗
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║   ██║██║     ███████║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ╚██╗ ██╔╝██║     ██╔══██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗     ╚████╔╝ ╚██████╗██║  ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝      ╚═══╝   ╚═════╝╚═╝  ╚═╝

*/

/// @title SablierMerkleVCA
/// @notice See the documentation in {ISablierMerkleVCA}.
contract SablierMerkleVCA is
    ISablierMerkleVCA, // 3 inherited components
    SablierMerkleSignature // 5 inherited components
{
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    uint128 public immutable override AGGREGATE_AMOUNT;

    /// @inheritdoc ISablierMerkleVCA
    UD60x18 public immutable override UNLOCK_PERCENTAGE;

    /// @inheritdoc ISablierMerkleVCA
    uint40 public immutable override VESTING_END_TIME;

    /// @inheritdoc ISablierMerkleVCA
    uint40 public immutable override VESTING_START_TIME;

    /// @inheritdoc ISablierMerkleVCA
    bool public override isRedistributionEnabled;

    /// @inheritdoc ISablierMerkleVCA
    uint128 public override totalForgoneAmount;

    /// @inheritdoc ISablierMerkleVCA
    uint128 public override totalRedistributionAmountPaid;

    /// @dev Tracks the full amount allocated to the recipients who claimed before the vesting end time.
    uint128 private _fullAmountAllocatedToEarlyClaimers;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleVCA.ConstructorParams memory campaignParams,
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
    {
        // Effect: set the immutable variables.
        AGGREGATE_AMOUNT = campaignParams.aggregateAmount;
        UNLOCK_PERCENTAGE = campaignParams.unlockPercentage;
        VESTING_END_TIME = campaignParams.vestingEndTime;
        VESTING_START_TIME = campaignParams.vestingStartTime;

        // Effect: set the enable redistribution flag.
        isRedistributionEnabled = campaignParams.enableRedistribution;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function calculateClaimAmount(uint128 fullAmount, uint40 claimTime) external view override returns (uint128) {
        // Zero is a sentinel value for `block.timestamp`.
        if (claimTime == 0) {
            claimTime = uint40(block.timestamp);
        }

        // Calculate and return the claim amount.
        return _calculateClaimAmount(fullAmount, claimTime);
    }

    /// @inheritdoc ISablierMerkleVCA
    function calculateForgoneAmount(uint128 fullAmount, uint40 claimTime) external view override returns (uint128) {
        // Zero is a sentinel value for `block.timestamp`.
        if (claimTime == 0) {
            claimTime = uint40(block.timestamp);
        }

        // Check: the claim time is not less than the vesting start time.
        if (claimTime < VESTING_START_TIME) {
            revert Errors.SablierMerkleVCA_VestingNotStarted({
                claimTime: claimTime,
                vestingStartTime: VESTING_START_TIME
            });
        }

        return fullAmount - _calculateClaimAmount(fullAmount, claimTime);
    }

    /// @inheritdoc ISablierMerkleVCA
    function calculateRedistributionRewards(uint128 fullAmount) external view override returns (uint128) {
        // Check: redistribution is enabled.
        if (!isRedistributionEnabled) {
            revert Errors.SablierMerkleVCA_RedistributionNotEnabled();
        }

        // Calculate and return the redistribution rewards.
        return _calculateRedistributionRewards(fullAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function claimTo(
        uint256 index,
        address to,
        uint128 fullAmount,
        bytes32[] calldata merkleProof
    )
        external
        payable
        override
        revertIfNot(ClaimType.DEFAULT)
        notZeroAddress(to)
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: fullAmount, merkleProof: merkleProof });

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, fullAmount: fullAmount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleVCA
    function claimViaAttestation(
        uint256 index,
        address to,
        uint128 fullAmount,
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
        _preProcessClaim({ index: index, recipient: msg.sender, amount: fullAmount, merkleProof: merkleProof });

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, fullAmount: fullAmount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleVCA
    function claimViaSig(
        uint256 index,
        address recipient,
        address to,
        uint128 fullAmount,
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
        _verifyClaimSignature(index, recipient, to, fullAmount, validFrom, signature);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, fullAmount, merkleProof);

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: to, fullAmount: fullAmount, viaSig: true });
    }

    /// @inheritdoc ISablierMerkleVCA
    function enableRedistribution() external override onlyAdmin {
        // Check: `VESTING_END_TIME` is in the future.
        if (VESTING_END_TIME <= block.timestamp) {
            revert Errors.SablierMerkleVCA_VestingEndTimeNotInFuture(VESTING_END_TIME, block.timestamp);
        }

        // Check: the redistribution is not already enabled.
        if (isRedistributionEnabled) {
            revert Errors.SablierMerkleVCA_RedistributionAlreadyEnabled();
        }

        // Effect: set the value to true.
        isRedistributionEnabled = true;

        // Log the event.
        emit RedistributionEnabled();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _calculateClaimAmount(uint128 fullAmount, uint40 claimTime) private view returns (uint128) {
        // If the claim time is less than the vesting start time, there's nothing to calculate, so we return zero.
        if (claimTime < VESTING_START_TIME) {
            return 0;
        }

        // If the vesting period has ended, the full amount can be claimed.
        if (claimTime >= VESTING_END_TIME) {
            return fullAmount;
        }
        // Otherwise, calculate the claim amount based on the elapsed time.
        else {
            // Calculate the initial unlock amount.
            uint128 unlockAmount = ud(fullAmount).mul(UNLOCK_PERCENTAGE).intoUint128();

            uint40 elapsedTime;
            uint40 totalDuration;

            // Safe because overflows are prevented by the checks above.
            unchecked {
                elapsedTime = claimTime - VESTING_START_TIME;
                totalDuration = VESTING_END_TIME - VESTING_START_TIME;
            }

            // Safe to cast because the result is less than `remainderAmount`, which fits within `uint128`.
            uint256 remainderAmount = uint256(fullAmount - unlockAmount);
            uint128 vestedAmount = uint128((remainderAmount * elapsedTime) / totalDuration);
            return unlockAmount + vestedAmount;
        }
    }

    /// @notice Calculates the redistribution rewards for a given full amount.
    function _calculateRedistributionRewards(uint256 fullAmount) private view returns (uint128 rewards) {
        // Return zero if total forgone amount is zero.
        if (totalForgoneAmount == 0) {
            return 0;
        }

        // Return zero if aggregate amount does not exceed the amount allocated to early claimers.
        if (AGGREGATE_AMOUNT <= _fullAmountAllocatedToEarlyClaimers) {
            return 0;
        }

        // Calculate the total amount allocated to the remaining claimers.
        uint128 fullAmountAllocatedToRemainingClaimers;
        unchecked {
            // Safe to use unchecked because it cannot overflow due to above check.
            fullAmountAllocatedToRemainingClaimers = AGGREGATE_AMOUNT - _fullAmountAllocatedToEarlyClaimers;
        }

        // Calculate the rewards.
        rewards = ((fullAmount * totalForgoneAmount) / fullAmountAllocatedToRemainingClaimers).toUint128();
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by handling the tokens transfer and emitting an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 fullAmount, bool viaSig) private {
        // Calculate the claim amount.
        uint128 claimAmount = _calculateClaimAmount(fullAmount, uint40(block.timestamp));

        // Check: the claim amount is not zero.
        if (claimAmount == 0) {
            revert Errors.SablierMerkleVCA_ClaimAmountZero(recipient);
        }

        uint128 forgoneAmount;
        uint128 rewardAmount;
        uint128 transferAmount = claimAmount;

        // Effect: update the total forgone amount and the total amount claimed by early claimers.
        if (claimAmount < fullAmount) {
            // Its safe to use unchecked because the value can't underflow.
            unchecked {
                forgoneAmount = fullAmount - claimAmount;
            }
            totalForgoneAmount += forgoneAmount;
            _fullAmountAllocatedToEarlyClaimers += fullAmount;
        } else {
            // Although the claim amount should never exceed the full amount, this assertion prevents excessive claiming
            // in case of a calculation error.
            assert(claimAmount == fullAmount);

            if (isRedistributionEnabled) {
                // Calculate the reward amount.
                rewardAmount = _calculateRedistributionRewards(fullAmount);

                // Calculate the remaining redistribution balance.
                uint128 remainingRedistributionBalance = totalForgoneAmount - totalRedistributionAmountPaid;

                // If reward amount exceeds the remaining redistribution balance, cap it to the remaining balance. In a
                // very unlikely scenario, the reward amount can exceed the remaining redistribution balance if
                // `AGGREGATE_AMOUNT` is set lower than the actual total allocations in the Merkle tree.
                if (rewardAmount > remainingRedistributionBalance) {
                    rewardAmount = remainingRedistributionBalance;
                }

                // Update the transfer amount if there are rewards to distribute.
                if (rewardAmount > 0) {
                    totalRedistributionAmountPaid += rewardAmount;
                    transferAmount += rewardAmount;

                    // Log the event.
                    emit RedistributionReward(index, recipient, rewardAmount, to);
                }
            }
        }

        // Interaction: transfer the tokens to the recipient.
        TOKEN.safeTransfer({ to: to, value: transferAmount });

        // Emit claim event.
        emit ClaimVCA(index, recipient, claimAmount, forgoneAmount, to, viaSig);
    }
}
