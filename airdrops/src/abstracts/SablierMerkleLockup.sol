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
    ISablierLockup public immutable override LOCKUP;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override STREAM_CANCELABLE;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override STREAM_TRANSFERABLE;

    /// @inheritdoc ISablierMerkleLockup
    string public override shape;

    /// @dev A mapping of stream IDs associated with the airdrops claimed by the recipient.
    mapping(address recipient => uint256[] streamIds) internal _claimedStreams;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables, and max approving the Lockup
    /// contract.
    constructor(
        address campaignCreator,
        string memory campaignName,
        bool cancelable,
        ISablierLockup lockup,
        uint40 expiration,
        address initialAdmin,
        string memory ipfsCID,
        bytes32 merkleRoot,
        string memory _shape,
        IERC20 token,
        bool transferable
    )
        SablierMerkleBase(campaignCreator, campaignName, expiration, initialAdmin, ipfsCID, merkleRoot, token)
    {
        LOCKUP = lockup;
        shape = _shape;
        STREAM_CANCELABLE = cancelable;
        STREAM_TRANSFERABLE = transferable;

        // Max approve the Lockup contract to spend funds from the Merkle Lockup campaigns.
        TOKEN.forceApprove(address(LOCKUP), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockup
    function claimedStreams(address recipient) external view override returns (uint256[] memory) {
        return _claimedStreams[recipient];
    }
}
