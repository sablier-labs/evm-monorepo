// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud, UD60x18, uUNIT } from "@prb/math/src/UD60x18.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleVCA } from "./types/DataTypes.sol";

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
    ISablierMerkleVCA, // 2 inherited components
    SablierMerkleBase // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    UD60x18 public immutable override UNLOCK_PERCENTAGE;

    /// @inheritdoc ISablierMerkleVCA
    uint40 public immutable override VESTING_END_TIME;

    /// @inheritdoc ISablierMerkleVCA
    uint40 public immutable override VESTING_START_TIME;

    /// @inheritdoc ISablierMerkleVCA
    uint256 public override totalForgoneAmount;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleVCA.ConstructorParams memory params,
        address campaignCreator
    )
        SablierMerkleBase(
            campaignCreator,
            params.campaignName,
            params.expiration,
            params.initialAdmin,
            params.ipfsCID,
            params.merkleRoot,
            params.token
        )
    {
        // Check: start time is not zero.
        if (params.startTime == 0) {
            revert Errors.SablierMerkleVCA_StartTimeZero();
        }

        // Check: vesting end time is greater than the vesting start time.
        if (params.endTime <= params.startTime) {
            revert Errors.SablierMerkleVCA_EndTimeNotGreaterThanStartTime({
                startTime: params.startTime,
                endTime: params.endTime
            });
        }

        // Check: campaign expiration is not zero.
        if (params.expiration == 0) {
            revert Errors.SablierMerkleVCA_ExpirationTimeZero();
        }

        // Check: campaign expiration is at least 1 week later than the end time.
        if (params.expiration < params.endTime + 1 weeks) {
            revert Errors.SablierMerkleVCA_ExpirationTooEarly({ endTime: params.endTime, expiration: params.expiration });
        }

        // Check: unlock percentage is not greater than 100%.
        if (params.unlockPercentage.unwrap() > uUNIT) {
            revert Errors.SablierMerkleVCA_UnlockPercentageTooHigh(params.unlockPercentage);
        }

        // Effect: set the immutable variables.
        UNLOCK_PERCENTAGE = params.unlockPercentage;
        VESTING_END_TIME = params.endTime;
        VESTING_START_TIME = params.startTime;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function calculateClaimAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128) {
        // Zero is a sentinel value for `block.timestamp`.
        if (claimTime == 0) {
            claimTime = uint40(block.timestamp);
        }

        // Calculate and return the claim amount.
        return _calculateClaimAmount(fullAmount, claimTime);
    }

    /// @inheritdoc ISablierMerkleVCA
    function calculateForgoneAmount(uint128 fullAmount, uint40 claimTime) external view returns (uint128) {
        // Zero is a sentinel value for `block.timestamp`.
        if (claimTime == 0) {
            claimTime = uint40(block.timestamp);
        }

        // If the claim time is less than the vesting start time, no amount can be forgone since the claim cannot be
        // made, so we return zero.
        if (claimTime < VESTING_START_TIME) {
            return 0;
        }

        return fullAmount - _calculateClaimAmount(fullAmount, claimTime);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _calculateClaimAmount(uint128 fullAmount, uint40 claimTime) internal view returns (uint128) {
        // If the claim time is less than the vesting start time, there's nothing to calculate, so we return zero.
        if (claimTime < VESTING_START_TIME) {
            return 0;
        }

        // Calculate the initial unlock amount.
        uint128 unlockAmount = ud(fullAmount).mul(UNLOCK_PERCENTAGE).intoUint128();

        // If the claim time is equal to the vesting start time, return the unlock amount.
        if (claimTime == VESTING_START_TIME) {
            return unlockAmount;
        }

        // If the vesting period has ended, the full amount can be claimed.
        if (claimTime >= VESTING_END_TIME) {
            return fullAmount;
        }
        // Otherwise, calculate the claim amount based on the elapsed time.
        else {
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

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 fullAmount) internal override {
        // Calculate the claim amount.
        uint128 claimAmount = _calculateClaimAmount(fullAmount, uint40(block.timestamp));

        // Check: the claim amount is not zero.
        if (claimAmount == 0) {
            revert Errors.SablierMerkleVCA_ClaimAmountZero(recipient);
        }

        uint128 forgoneAmount;

        // Effect: update the total forgone amount.
        if (claimAmount < fullAmount) {
            unchecked {
                forgoneAmount = fullAmount - claimAmount;
                totalForgoneAmount += forgoneAmount;
            }
        } else {
            // Although the claim amount should never exceed the full amount, this assertion prevents excessive claiming
            // in case of a calculation error.
            assert(claimAmount == fullAmount);
        }

        // Interaction: transfer the tokens to the recipient.
        TOKEN.safeTransfer({ to: recipient, value: claimAmount });

        // Log the claim.
        emit Claim(index, recipient, claimAmount, forgoneAmount);
    }
}
