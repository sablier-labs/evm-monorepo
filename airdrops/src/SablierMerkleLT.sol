// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { uUNIT } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud60x18, ZERO } from "@prb/math/src/UD60x18.sol";
import { ISablierLockup } from "@sablier/lockup/interfaces/ISablierLockup.sol";
import { Broker, Lockup, LockupTranched } from "@sablier/lockup/types/DataTypes.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleBase, MerkleLT } from "./types/DataTypes.sol";

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
    ISablierMerkleLT, // 2 inherited components
    SablierMerkleBase // 4 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLT
    bool public immutable override CANCELABLE;

    /// @inheritdoc ISablierMerkleLT
    ISablierLockup public immutable override LOCKUP;

    /// @inheritdoc ISablierMerkleLT
    uint40 public immutable override STREAM_START_TIME;

    /// @inheritdoc ISablierMerkleLT
    uint64 public immutable override TOTAL_PERCENTAGE;

    /// @inheritdoc ISablierMerkleLT
    bool public immutable override TRANSFERABLE;

    /// @dev The tranches with their respective unlock percentages and durations.
    MerkleLT.TrancheWithPercentage[] internal _tranchesWithPercentages;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 fee
    )
        SablierMerkleBase(baseParams, fee)
    {
        CANCELABLE = cancelable;
        LOCKUP = lockup;
        STREAM_START_TIME = streamStartTime;
        TRANSFERABLE = transferable;

        uint256 count = tranchesWithPercentages.length;

        // Calculate the total percentage of the tranches and save them in the contract state.
        uint64 totalPercentage;
        for (uint256 i = 0; i < count; ++i) {
            uint64 percentage = tranchesWithPercentages[i].unlockPercentage.unwrap();
            totalPercentage += percentage;
            _tranchesWithPercentages.push(tranchesWithPercentages[i]);
        }
        TOTAL_PERCENTAGE = totalPercentage;

        // Max approve the Lockup contract to spend funds from the MerkleLT contract.
        TOKEN.forceApprove(address(LOCKUP), type(uint256).max);
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

        // Interaction: create the stream via {SablierLockup-createWithTimestampsLT}.
        uint256 streamId = LOCKUP.createWithTimestampsLT(
            Lockup.CreateWithTimestamps({
                sender: admin,
                recipient: recipient,
                totalAmount: amount,
                asset: TOKEN,
                cancelable: CANCELABLE,
                transferable: TRANSFERABLE,
                timestamps: Lockup.Timestamps({ start: startTime, end: endTime }),
                broker: Broker({ account: address(0), fee: ZERO })
            }),
            tranches
        );

        // Log the claim.
        emit Claim(index, recipient, amount, streamId);
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

        // It should never be the case that the sum of the calculated amounts is greater than the claim amount because
        // PRBMath always rounds down.
        assert(calculatedAmountsSum <= claimAmount);

        // Since there can be rounding errors, the last tranche amount needs to be adjusted to ensure the sum of all
        // tranche amounts equals the claim amount.
        if (calculatedAmountsSum < claimAmount) {
            unchecked {
                tranches[trancheCount - 1].amount += claimAmount - calculatedAmountsSum;
            }
        }
    }
}
