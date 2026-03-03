// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { SablierMerkleBase } from "./abstracts/SablierMerkleBase.sol";
import { ISablierMerkleExecute } from "./interfaces/ISablierMerkleExecute.sol";
import { Errors } from "./libraries/Errors.sol";
import { ClaimType, MerkleBase } from "./types/MerkleBase.sol";
import { MerkleExecute } from "./types/MerkleExecute.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ███████╗██╗  ██╗███████╗ ██████╗██╗   ██╗████████╗███████╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██╔════╝╚██╗██╔╝██╔════╝██╔════╝██║   ██║╚══██╔══╝██╔════╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      █████╗   ╚███╔╝ █████╗  ██║     ██║   ██║   ██║   █████╗
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██╔══╝   ██╔██╗ ██╔══╝  ██║     ██║   ██║   ██║   ██╔══╝
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ███████╗██╔╝ ██╗███████╗╚██████╗╚██████╔╝   ██║   ███████╗
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝    ╚═╝   ╚══════╝

*/

/// @title SablierMerkleExecute
/// @notice See the documentation in {ISablierMerkleExecute}.
contract SablierMerkleExecute is
    ISablierMerkleExecute, // 2 inherited components
    ReentrancyGuard, // 1 inherited component
    SablierMerkleBase // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleExecute
    bytes4 public immutable override SELECTOR;

    /// @inheritdoc ISablierMerkleExecute
    address public immutable override TARGET;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(
        MerkleExecute.ConstructorParams memory campaignParams,
        address campaignCreator,
        address comptroller
    )
        SablierMerkleBase(MerkleBase.ConstructorParams({
                campaignCreator: campaignCreator,
                campaignName: campaignParams.campaignName,
                campaignStartTime: campaignParams.campaignStartTime,
                claimType: ClaimType.EXECUTE,
                comptroller: comptroller,
                expiration: campaignParams.expiration,
                initialAdmin: campaignParams.initialAdmin,
                ipfsCID: campaignParams.ipfsCID,
                merkleRoot: campaignParams.merkleRoot,
                token: campaignParams.token
            }))
    {
        // Effect: set the immutable state variables.
        SELECTOR = campaignParams.selector;
        TARGET = campaignParams.target;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleExecute
    function claimAndExecute(
        uint256 index,
        uint128 amount,
        bytes32[] calldata merkleProof,
        bytes calldata selectorArguments
    )
        external
        payable
        override
        nonReentrant
    {
        // Check, Effect and Interaction: Pre-process the claim parameters on behalf of `msg.sender`.
        _preProcessClaim({ index: index, recipient: msg.sender, amount: amount, merkleProof: merkleProof });

        // Cache the token balance before the external call.
        uint256 balanceBefore = TOKEN.balanceOf(address(this));

        // Interaction: Give allowance to the target contract.
        // The {SafeERC20.forceApprove} function is used to handle special ERC-20 tokens (e.g. USDT) that require the
        // current allowance to be zero before setting it to a non-zero value.
        TOKEN.forceApprove({ spender: TARGET, value: amount });

        // Prepare the call data by concatenating the selector and the arguments.
        bytes memory callData = abi.encodePacked(SELECTOR, selectorArguments);

        // Interaction: Execute the call on the target contract.
        (bool success, bytes memory returnData) = TARGET.call(callData);

        // Check: the call to the target contract succeeded. Otherwise, revert.
        if (!success) {
            assembly {
                // Get the length of the result stored in the first 32 bytes.
                let returnDataSize := mload(returnData)

                // Forward the pointer by 32 bytes to skip the length argument, and revert with the result.
                revert(add(32, returnData), returnDataSize)
            }
        }

        // Check: the transferred amount is equal to the claim amount.
        uint256 amountTransferred = balanceBefore - TOKEN.balanceOf(address(this));
        if (amountTransferred != amount) {
            revert Errors.SablierMerkleExecute_NotFullAmountTransferred(amountTransferred, amount);
        }

        // Interaction: Revoke the allowance.
        TOKEN.forceApprove({ spender: TARGET, value: 0 });

        // Emit claim event.
        emit ClaimExecute(index, msg.sender, amount, TARGET);
    }
}
