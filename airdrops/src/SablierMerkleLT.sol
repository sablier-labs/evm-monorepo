// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { uUNIT } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup, LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { SablierMerkleLockup } from "./abstracts/SablierMerkleLockup.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleLT } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ██╗     ████████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██║     ╚══██╔══╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      ██║        ██║
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██║        ██║
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ███████╗   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝   ╚═╝

*/

/// @title SablierMerkleLT
/// @notice See the documentation in {ISablierMerkleLT}.
contract SablierMerkleLT is
    ISablierMerkleLT, // 3 inherited components
    SablierMerkleLockup // 5 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLT
    uint40 public immutable override STREAM_START_TIME;

    /// @inheritdoc ISablierMerkleLT
    uint64 public immutable override TOTAL_PERCENTAGE;

    /// @dev The tranches with their respective unlock percentages and durations.
    MerkleLT.TrancheWithPercentage[] private _tranchesWithPercentages;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleLT.ConstructorParams memory params,
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
        STREAM_START_TIME = params.streamStartTime;

        uint256 count = params.tranchesWithPercentages.length;

        // Calculate the total percentage of the tranches and save them in the contract state.
        uint64 totalPercentage;
        for (uint256 i = 0; i < count; ++i) {
            uint64 percentage = params.tranchesWithPercentages[i].unlockPercentage.unwrap();
            totalPercentage += percentage;
            _tranchesWithPercentages.push(params.tranchesWithPercentages[i]);
        }
        TOTAL_PERCENTAGE = totalPercentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLT
    function getTranchesWithPercentages() external view override returns (MerkleLT.TrancheWithPercentage[] memory) {
        return _tranchesWithPercentages;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc SablierMerkleBase
    function _claim(uint256 index, address recipient, uint128 amount) internal override {
        // Check: the sum of percentages equals 100%.
        if (TOTAL_PERCENTAGE != uUNIT) {
            revert Errors.SablierMerkleLT_TotalPercentageNotOneHundred(TOTAL_PERCENTAGE);
        }

        // Calculate the tranches based on the unlock percentages.
        (uint40 startTime, LockupTranched.Tranche[] memory tranches) = _calculateStartTimeAndTranches(amount);

        // Calculate the stream's end time.
        uint40 endTime;
        unchecked {
            endTime = tranches[tranches.length - 1].timestamp;
        }

        // If the stream end time is not in the future, transfer the amount directly to the recipient.
        if (endTime <= block.timestamp) {
            // Interaction: transfer the token.
            TOKEN.safeTransfer(recipient, amount);

            // Log the claim.
            emit Claim(index, recipient, amount);
        }
        // Otherwise, create the Lockup stream.
        else {
            // Interaction: create the stream via {SablierLockup-createWithTimestampsLT}.
            uint256 streamId = LOCKUP.createWithTimestampsLT(
                Lockup.CreateWithTimestamps({
                    sender: admin,
                    recipient: recipient,
                    depositAmount: amount,
                    token: TOKEN,
                    cancelable: STREAM_CANCELABLE,
                    transferable: STREAM_TRANSFERABLE,
                    timestamps: Lockup.Timestamps({ start: startTime, end: endTime }),
                    shape: shape
                }),
                tranches
            );

            // Effect: push the stream ID into the `_claimedStreams` array for the recipient.
            _claimedStreams[recipient].push(streamId);

            // Log the claim.
            emit Claim(index, recipient, amount, streamId);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the start time, and the tranches based on the claim amount and the unlock percentages for each
    /// tranche.
    function _calculateStartTimeAndTranches(uint128 claimAmount)
        internal
        view
        returns (uint40 startTime, LockupTranched.Tranche[] memory tranches)
    {
        // Calculate the start time.
        if (STREAM_START_TIME == 0) {
            startTime = uint40(block.timestamp);
        } else {
            startTime = STREAM_START_TIME;
        }

        // Load the tranches in memory (to save gas).
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = _tranchesWithPercentages;

        // Declare the variables needed for calculation.
        uint128 calculatedAmountsSum;
        UD60x18 claimAmountUD = ud60x18(claimAmount);
        uint256 trancheCount = tranchesWithPercentages.length;
        tranches = new LockupTranched.Tranche[](trancheCount);

        unchecked {
            // Convert the tranche's percentage from the `UD2x18` to the `UD60x18` type.
            UD60x18 percentage = (tranchesWithPercentages[0].unlockPercentage).intoUD60x18();

            // Calculate the tranche's amount by multiplying the claim amount by the unlock percentage.
            uint128 calculatedAmount = claimAmountUD.mul(percentage).intoUint128();

            // The first tranche is precomputed because it is needed in the for loop below.
            tranches[0] = LockupTranched.Tranche({
                amount: calculatedAmount,
                timestamp: startTime + tranchesWithPercentages[0].duration
            });

            // Add the calculated tranche amount.
            calculatedAmountsSum += calculatedAmount;

            // Iterate over each tranche to calculate its timestamp and unlock amount.
            for (uint256 i = 1; i < trancheCount; ++i) {
                percentage = (tranchesWithPercentages[i].unlockPercentage).intoUD60x18();
                calculatedAmount = claimAmountUD.mul(percentage).intoUint128();

                tranches[i] = LockupTranched.Tranche({
                    amount: calculatedAmount,
                    timestamp: tranches[i - 1].timestamp + tranchesWithPercentages[i].duration
                });

                calculatedAmountsSum += calculatedAmount;
            }
        }

        // Since there can be rounding errors, the last tranche amount needs to be adjusted to ensure the sum of all
        // tranche amounts equals the claim amount.
        if (calculatedAmountsSum < claimAmount) {
            unchecked {
                tranches[trancheCount - 1].amount += claimAmount - calculatedAmountsSum;
            }
        }
    }
}
