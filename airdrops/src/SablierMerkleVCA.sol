// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
    uint256 public override totalForgoneAmount;

    /// @dev See the documentation in {ISablierMerkleVCA.getSchedule}.
    MerkleVCA.Schedule private _schedule;

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
        // Check: schedule start time is not zero.
        if (params.schedule.startTime == 0) {
            revert Errors.SablierMerkleVCA_VestingStartTimeZero();
        }

        // Check: vesting end time is greater than the schedule start time.
        if (params.schedule.endTime <= params.schedule.startTime) {
            revert Errors.SablierMerkleVCA_StartTimeGreaterThanEndTime({
                startTime: params.schedule.startTime,
                endTime: params.schedule.endTime
            });
        }

        // Check: campaign expiration is not zero.
        if (params.expiration == 0) {
            revert Errors.SablierMerkleVCA_ExpiryTimeZero();
        }

        // Check: campaign expiration is at least 1 week later than the vesting end time.
        if (params.expiration < params.schedule.endTime + 1 weeks) {
            revert Errors.SablierMerkleVCA_ExpirationTooEarly({
                endTime: params.schedule.endTime,
                expiration: params.expiration
            });
        }

        _schedule = params.schedule;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleVCA
    function calculateClaimAmount(uint128 fullAmount) external pure returns (uint128) {
        // TODO: implement
        fullAmount;
        return 0;
    }

    /// @inheritdoc ISablierMerkleVCA
    function calculateForgoneAmount(uint128 fullAmount) external pure returns (uint128) {
        // TODO: implement
        fullAmount;
        return 0;
    }

    /// @inheritdoc ISablierMerkleVCA
    function getSchedule() external view override returns (MerkleVCA.Schedule memory) {
        return _schedule;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 fullAmount) internal override {
        uint40 blockTimestamp = uint40(block.timestamp);

        // Load the vesting schedule into memory to avoid multiple SLOADs.
        MerkleVCA.Schedule memory vestingSchedule = _schedule;

        // Check: schedule start time is in the past.
        if (vestingSchedule.startTime >= blockTimestamp) {
            revert Errors.SablierMerkleVCA_ClaimNotStarted(vestingSchedule.startTime);
        }

        // Calculate the claim and foregone amount.
        uint128 claimAmount;
        uint128 forgoneAmount;

        if (vestingSchedule.endTime <= blockTimestamp) {
            // If the vesting period has ended, the recipient can claim the full amount.
            claimAmount = fullAmount;
        } else {
            // Otherwise, calculate the claimable amount based on the elapsed time.
            uint40 elapsedTime = blockTimestamp - vestingSchedule.startTime;
            uint40 totalDuration = vestingSchedule.endTime - vestingSchedule.startTime;

            // Safe to cast because the division results into a value less than `fullAmount`, which is already an
            // `uint128`.
            claimAmount = uint128((uint256(fullAmount) * elapsedTime) / totalDuration);

            // Effect: update the forgone amount.
            forgoneAmount = fullAmount - claimAmount;
            totalForgoneAmount += forgoneAmount;
        }

        // Interaction: transfer the tokens to the recipient.
        TOKEN.safeTransfer({ to: recipient, value: claimAmount });

        // Log the claim.
        emit Claim(index, recipient, claimAmount, forgoneAmount);
    }
}
