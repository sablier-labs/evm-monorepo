// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { uUNIT } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { ISablierLockupTranched } from "../core/interfaces/ISablierLockupTranched.sol";
import { Broker, LockupTranched } from "../core/types/DataTypes.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { Errors } from "./libraries/Errors.sol";
import { MerkleBase, MerkleLT } from "./types/DataTypes.sol";

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
    ISablierLockupTranched public immutable override LOCKUP_TRANCHED;

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
        ISablierLockupTranched lockupTranched,
        bool cancelable,
        bool transferable,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages
    )
        SablierMerkleBase(baseParams)
    {
        CANCELABLE = cancelable;
        LOCKUP_TRANCHED = lockupTranched;
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
        ASSET.forceApprove(address(LOCKUP_TRANCHED), type(uint256).max);
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
        LockupTranched.TrancheWithDuration[] memory tranches = _calculateTranches(amount);

        // Interaction: create the stream via {SablierLockupTranched}.
        uint256 streamId = LOCKUP_TRANCHED.createWithDurations(
            LockupTranched.CreateWithDurations({
                sender: admin,
                recipient: recipient,
                totalAmount: amount,
                asset: ASSET,
                cancelable: CANCELABLE,
                transferable: TRANSFERABLE,
                tranches: tranches,
                broker: Broker({ account: address(0), fee: ZERO })
            })
        );

        // Log the claim.
        emit Claim(index, recipient, amount, streamId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the tranches based on the claim amount and the unlock percentages for each tranche.
    function _calculateTranches(
        uint128 claimAmount
    )
        internal
        view
        returns (LockupTranched.TrancheWithDuration[] memory tranches)
    {
        // Load the tranches in memory (to save gas).
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = _tranchesWithPercentages;

        // Declare the variables needed for calculation.
        uint128 calculatedAmountsSum;
        UD60x18 claimAmountUD = ud60x18(claimAmount);
        uint256 trancheCount = tranchesWithPercentages.length;
        tranches = new LockupTranched.TrancheWithDuration[](trancheCount);

        // Iterate over each tranche to calculate its unlock amount.
        for (uint256 i = 0; i < trancheCount; ++i) {
            // Convert the tranche's percentage from the `UD2x18` to the `UD60x18` type.
            UD60x18 percentage = (tranchesWithPercentages[i].unlockPercentage).intoUD60x18();

            // Calculate the tranche's amount by multiplying the claim amount by the unlock percentage.
            uint128 calculatedAmount = claimAmountUD.mul(percentage).intoUint128();

            // Create the tranche with duration.
            tranches[i] = LockupTranched.TrancheWithDuration({
                amount: calculatedAmount,
                duration: tranchesWithPercentages[i].duration
            });

            // Add the calculated tranche amount.
            calculatedAmountsSum += calculatedAmount;
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
