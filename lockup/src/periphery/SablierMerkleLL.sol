// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

import { ISablierLockupLinear } from "../core/interfaces/ISablierLockupLinear.sol";
import { Broker, LockupLinear } from "../core/types/DataTypes.sol";

import { SablierMerkleLockup } from "./abstracts/SablierMerkleLockup.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { MerkleLockup } from "./types/DataTypes.sol";

/// @title SablierMerkleLL
/// @notice See the documentation in {ISablierMerkleLL}.
contract SablierMerkleLL is
    ISablierMerkleLL, // 2 inherited components
    SablierMerkleLockup // 4 inherited components
{
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    ISablierLockupLinear public immutable override LOCKUP_LINEAR;

    /// @inheritdoc ISablierMerkleLL
    LockupLinear.Durations public override streamDurations;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        MerkleLockup.ConstructorParams memory baseParams,
        ISablierLockupLinear lockupLinear,
        LockupLinear.Durations memory streamDurations_
    )
        SablierMerkleLockup(baseParams)
    {
        LOCKUP_LINEAR = lockupLinear;
        streamDurations = streamDurations_;

        // Max approve the Lockup contract to spend funds from the MerkleLockup contract.
        ASSET.forceApprove(address(LOCKUP_LINEAR), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLL
    function claim(
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        external
        override
        returns (uint256 streamId)
    {
        // Generate the Merkle tree leaf by hashing the corresponding parameters. Hashing twice prevents second
        // preimage attacks.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, recipient, amount))));

        // Check: validate the function.
        _checkClaim(index, leaf, merkleProof);

        // Effect: mark the index as claimed.
        _claimedBitMap.set(index);

        // Interaction: create the stream via {SablierLockupLinear}.
        streamId = LOCKUP_LINEAR.createWithDurations(
            LockupLinear.CreateWithDurations({
                sender: admin,
                recipient: recipient,
                totalAmount: amount,
                asset: ASSET,
                cancelable: CANCELABLE,
                transferable: TRANSFERABLE,
                durations: streamDurations,
                broker: Broker({ account: address(0), fee: ud(0) })
            })
        );

        // Log the claim.
        emit Claim(index, recipient, amount, streamId);
    }
}
