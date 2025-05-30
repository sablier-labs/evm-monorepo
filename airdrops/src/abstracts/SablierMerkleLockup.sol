// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

import { ISablierMerkleLockup } from "../interfaces/ISablierMerkleLL.sol";
import { SablierMerkleBase } from "./SablierMerkleBase.sol";

/// @title SablierMerkleLockup
/// @notice See the documentation in {ISablierMerkleLockup}.
abstract contract SablierMerkleLockup is
    ISablierMerkleLockup, // 2 inherited components,
    SablierMerkleBase // 3 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockup
    ISablierLockup public immutable override SABLIER_LOCKUP;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override STREAM_CANCELABLE;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override STREAM_TRANSFERABLE;

    /// @inheritdoc ISablierMerkleLockup
    string public override streamShape;

    /// @dev A mapping between recipient addresses and Lockup streams created through the claim function.
    mapping(address recipient => uint256[] streamIds) internal _claimedStreams;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state vars, and max approving the Lockup contract.
    constructor(
        address campaignCreator,
        string memory campaignName,
        uint40 campaignStartTime,
        bool cancelable,
        ISablierLockup sablierLockup,
        uint40 expiration,
        address initialAdmin,
        string memory ipfsCID,
        bytes32 merkleRoot,
        string memory shape_,
        IERC20 token,
        bool transferable
    )
        SablierMerkleBase(
            campaignCreator,
            campaignName,
            campaignStartTime,
            expiration,
            initialAdmin,
            ipfsCID,
            merkleRoot,
            token
        )
    {
        SABLIER_LOCKUP = sablierLockup;
        streamShape = shape_;
        STREAM_CANCELABLE = cancelable;
        STREAM_TRANSFERABLE = transferable;

        // Max approve the Lockup contract to spend funds from the Merkle Lockup campaigns.
        TOKEN.forceApprove({ spender: address(SABLIER_LOCKUP), value: type(uint256).max });
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockup
    function claimedStreams(address recipient) external view override returns (uint256[] memory) {
        return _claimedStreams[recipient];
    }
}
