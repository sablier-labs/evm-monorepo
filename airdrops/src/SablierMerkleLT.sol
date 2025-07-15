// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { uUNIT } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Lockup, LockupTranched } from "@sablier/lockup/src/types/DataTypes.sol";

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
    uint64 public immutable override TRANCHES_TOTAL_PERCENTAGE;

    /// @inheritdoc ISablierMerkleLT
    uint40 public immutable override VESTING_START_TIME;

    /// @dev The tranches with their respective unlock percentages and durations.
    MerkleLT.TrancheWithPercentage[] private _tranchesWithPercentages;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleLT.ConstructorParams memory params,
        address campaignCreator,
        address comptroller
    )
        SablierMerkleLockup(
            campaignCreator,
            params.campaignName,
            params.campaignStartTime,
            params.cancelable,
            comptroller,
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
        VESTING_START_TIME = params.vestingStartTime;

        uint256 count = params.tranchesWithPercentages.length;

        // Calculate the total percentage of the tranches and save them in the contract state.
        uint64 totalPercentage;
        for (uint256 i = 0; i < count; ++i) {
            uint64 percentage = params.tranchesWithPercentages[i].unlockPercentage.unwrap();
            totalPercentage += percentage;
            _tranchesWithPercentages.push(params.tranchesWithPercentages[i]);
        }
        TRANCHES_TOTAL_PERCENTAGE = totalPercentage;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLT
    function tranchesWithPercentages() external view override returns (MerkleLT.TrancheWithPercentage[] memory) {
        return _tranchesWithPercentages;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLT
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

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: recipient, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleLT
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

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of `msg.sender`.
        _postProcessClaim({ index: index, recipient: msg.sender, to: to, amount: amount, viaSig: false });
    }

    /// @inheritdoc ISablierMerkleLT
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
        notZeroAddress(to)
    {
        // Check: the signature is valid and the recovered signer matches the recipient.
        _checkSignature(index, recipient, to, amount, validFrom, signature);

        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of the recipient.
        _preProcessClaim(index, recipient, amount, merkleProof);

        // Check, Effect and Interaction: Post-process the claim parameters on behalf of the recipient.
        _postProcessClaim({ index: index, recipient: recipient, to: to, amount: amount, viaSig: true });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculates the vesting start time, and the tranches based on the claim amount and the unlock percentages
    /// for each tranche.
    function _calculateStartTimeAndTranches(uint128 claimAmount)
        private
        view
        returns (uint40 vestingStartTime, LockupTranched.Tranche[] memory tranches)
    {
        // Calculate the vesting start time. Zero is a sentinel value for `block.timestamp`.
        if (VESTING_START_TIME == 0) {
            vestingStartTime = uint40(block.timestamp);
        } else {
            vestingStartTime = VESTING_START_TIME;
        }

        // Load the tranches in memory (to save gas).
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPct = _tranchesWithPercentages;

        // Declare the variables needed for calculation.
        uint128 calculatedAmountsSum;
        UD60x18 claimAmountUD = ud60x18(claimAmount);
        uint256 trancheCount = tranchesWithPct.length;
        tranches = new LockupTranched.Tranche[](trancheCount);

        unchecked {
            // Convert the tranche's percentage from the `UD2x18` to the `UD60x18` type.
            UD60x18 percentage = (tranchesWithPct[0].unlockPercentage).intoUD60x18();

            // Calculate the tranche's amount by multiplying the claim amount by the unlock percentage.
            uint128 calculatedAmount = claimAmountUD.mul(percentage).intoUint128();

            // Add the calculated tranche amount.
            calculatedAmountsSum += calculatedAmount;

            // The first tranche is precomputed because it is needed in the for loop below.
            tranches[0] = LockupTranched.Tranche({
                amount: calculatedAmount,
                timestamp: vestingStartTime + tranchesWithPct[0].duration
            });

            // Iterate over each tranche to calculate its timestamp and unlock amount.
            for (uint256 i = 1; i < trancheCount; ++i) {
                percentage = (tranchesWithPct[i].unlockPercentage).intoUD60x18();
                calculatedAmount = claimAmountUD.mul(percentage).intoUint128();
                calculatedAmountsSum += calculatedAmount;

                tranches[i] = LockupTranched.Tranche({
                    amount: calculatedAmount,
                    timestamp: tranches[i - 1].timestamp + tranchesWithPct[i].duration
                });
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

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Post-processes the claim execution by creating the stream or transferring the tokens directly and emitting
    /// an event.
    function _postProcessClaim(uint256 index, address recipient, address to, uint128 amount, bool viaSig) private {
        // Check: the sum of percentages equals 100%.
        if (TRANCHES_TOTAL_PERCENTAGE != uUNIT) {
            revert Errors.SablierMerkleLT_TotalPercentageNotOneHundred(TRANCHES_TOTAL_PERCENTAGE);
        }

        // Declare the variables needed for the stream creation.
        Lockup.Timestamps memory timestamps;
        LockupTranched.Tranche[] memory tranches;

        // Calculate the tranches based on the unlock percentages.
        (timestamps.start, tranches) = _calculateStartTimeAndTranches(amount);

        // Calculate the stream's end time.
        unchecked {
            timestamps.end = tranches[tranches.length - 1].timestamp;
        }

        // If the stream end time is not in the future, transfer the amount directly to the `to` address.
        if (timestamps.end <= block.timestamp) {
            // Interaction: transfer the tokens to the `to` address.
            TOKEN.safeTransfer(to, amount);

            // Emit claim event.
            emit ClaimLTWithTransfer(index, recipient, amount, to, viaSig);
        }
        // Otherwise, create the Lockup stream.
        else {
            // Safe Interaction: create the stream with `to` as the stream recipient.
            uint256 streamId = SABLIER_LOCKUP.createWithTimestampsLT(
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
                tranches
            );

            // Effect: push the stream ID into the claimed streams array.
            _claimedStreams[recipient].push(streamId);

            // Emit claim event.
            emit ClaimLTWithVesting(index, recipient, amount, streamId, to, viaSig);
        }
    }
}
