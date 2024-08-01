// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

import { Adminable } from "../../core/abstracts/Adminable.sol";

import { ISablierMerkleLockup } from "../interfaces/ISablierMerkleLockup.sol";
import { MerkleLockup } from "../types/DataTypes.sol";
import { Errors } from "../libraries/Errors.sol";

/// @title SablierMerkleLockup
/// @notice See the documentation in {ISablierMerkleLockup}.
abstract contract SablierMerkleLockup is
    ISablierMerkleLockup, // 2 inherited component
    Adminable // 1 inherited component
{
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockup
    IERC20 public immutable override ASSET;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override CANCELABLE;

    /// @inheritdoc ISablierMerkleLockup
    uint40 public immutable override EXPIRATION;

    /// @inheritdoc ISablierMerkleLockup
    bytes32 public immutable override MERKLE_ROOT;

    /// @dev The name of the campaign stored as bytes32.
    bytes32 internal immutable NAME;

    /// @inheritdoc ISablierMerkleLockup
    bool public immutable override TRANSFERABLE;

    /// @inheritdoc ISablierMerkleLockup
    string public ipfsCID;

    /// @dev Packed booleans that record the history of claims.
    BitMaps.BitMap internal _claimedBitMap;

    /// @dev The timestamp when the first claim is made.
    uint40 internal _firstClaimTime;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Constructs the contract by initializing the immutable state variables.
    constructor(MerkleLockup.ConstructorParams memory params) {
        // Check: the campaign name is not greater than 32 bytes
        if (bytes(params.name).length > 32) {
            revert Errors.SablierMerkleLockup_CampaignNameTooLong({
                nameLength: bytes(params.name).length,
                maxLength: 32
            });
        }

        admin = params.initialAdmin;
        ASSET = params.asset;
        CANCELABLE = params.cancelable;
        EXPIRATION = params.expiration;
        ipfsCID = params.ipfsCID;
        MERKLE_ROOT = params.merkleRoot;
        NAME = bytes32(abi.encodePacked(params.name));
        TRANSFERABLE = params.transferable;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockup
    function getFirstClaimTime() external view override returns (uint40) {
        return _firstClaimTime;
    }

    /// @inheritdoc ISablierMerkleLockup
    function hasClaimed(uint256 index) public view override returns (bool) {
        return _claimedBitMap.get(index);
    }

    /// @inheritdoc ISablierMerkleLockup
    function hasExpired() public view override returns (bool) {
        return EXPIRATION > 0 && EXPIRATION <= block.timestamp;
    }

    /// @inheritdoc ISablierMerkleLockup
    function name() external view override returns (string memory) {
        return string(abi.encodePacked(NAME));
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleLockup
    function clawback(address to, uint128 amount) external override onlyAdmin {
        // Check: current timestamp is over the grace period and the campaign has not expired.
        if (_hasGracePeriodPassed() && !hasExpired()) {
            revert Errors.SablierMerkleLockup_ClawbackNotAllowed({
                blockTimestamp: block.timestamp,
                expiration: EXPIRATION,
                firstClaimTime: _firstClaimTime
            });
        }

        // Effect: transfer the tokens to the provided address.
        ASSET.safeTransfer(to, amount);

        // Log the clawback.
        emit Clawback(admin, to, amount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns a flag indicating whether the grace period has passed.
    /// @dev The grace period is 7 days after the first claim.
    function _hasGracePeriodPassed() internal view returns (bool) {
        return _firstClaimTime > 0 && block.timestamp > _firstClaimTime + 7 days;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Validates the parameters of the `claim` function, which is implemented by child contracts.
    function _checkClaim(uint256 index, bytes32 leaf, bytes32[] calldata merkleProof) internal {
        // Check: the campaign has not expired.
        if (hasExpired()) {
            revert Errors.SablierMerkleLockup_CampaignExpired({ blockTimestamp: block.timestamp, expiration: EXPIRATION });
        }

        // Check: the index has not been claimed.
        if (_claimedBitMap.get(index)) {
            revert Errors.SablierMerkleLockup_StreamClaimed(index);
        }

        // Check: the input claim is included in the Merkle tree.
        if (!MerkleProof.verify(merkleProof, MERKLE_ROOT, leaf)) {
            revert Errors.SablierMerkleLockup_InvalidProof();
        }

        // Effect: set the `_firstClaimTime` if its zero.
        if (_firstClaimTime == 0) {
            _firstClaimTime = uint40(block.timestamp);
        }
    }
}
