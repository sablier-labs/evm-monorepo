// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Adminable } from "@sablier/lockup/src/abstracts/Adminable.sol";

import { ISablierMerkleBase } from "./../interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "./../interfaces/ISablierMerkleFactory.sol";
import { Errors } from "./../libraries/Errors.sol";

/// @title SablierMerkleBase
/// @notice See the documentation in {ISablierMerkleBase}.
abstract contract SablierMerkleBase is
    ISablierMerkleBase, // 1 inherited component
    Adminable // 1 inherited component
{
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    uint40 public immutable override EXPIRATION;

    /// @inheritdoc ISablierMerkleBase
    address public immutable override FACTORY;

    /// @inheritdoc ISablierMerkleBase
    bytes32 public immutable override MERKLE_ROOT;

    /// @inheritdoc ISablierMerkleBase
    uint256 public immutable override MINIMUM_FEE;

    /// @inheritdoc ISablierMerkleBase
    IERC20 public immutable override TOKEN;

    /// @inheritdoc ISablierMerkleBase
    string public override campaignName;

    /// @inheritdoc ISablierMerkleBase
    string public override ipfsCID;

    /// @dev Packed booleans that record the history of claims.
    BitMaps.BitMap internal _claimedBitMap;

    /// @dev The timestamp when the first claim is made.
    uint40 internal _firstClaimTime;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructs the contract by initializing the immutable state variables.
    constructor(
        address campaignCreator,
        string memory _campaignName,
        uint40 expiration,
        address initialAdmin,
        string memory _ipfsCID,
        bytes32 merkleRoot,
        IERC20 token
    )
        Adminable(initialAdmin)
    {
        campaignName = _campaignName;
        EXPIRATION = expiration;
        FACTORY = msg.sender;
        MINIMUM_FEE = ISablierMerkleFactory(FACTORY).getFee(campaignCreator);
        MERKLE_ROOT = merkleRoot;
        TOKEN = token;
        ipfsCID = _ipfsCID;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    function getFirstClaimTime() external view override returns (uint40) {
        return _firstClaimTime;
    }

    /// @inheritdoc ISablierMerkleBase
    function hasClaimed(uint256 index) public view override returns (bool) {
        return _claimedBitMap.get(index);
    }

    /// @inheritdoc ISablierMerkleBase
    function hasExpired() public view override returns (bool) {
        return EXPIRATION > 0 && EXPIRATION <= block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
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
        // Check: the campaign has not expired.
        if (hasExpired()) {
            revert Errors.SablierMerkleBase_CampaignExpired({ blockTimestamp: block.timestamp, expiration: EXPIRATION });
        }

        // Check: `msg.value` is not less than the minimum fee.
        if (msg.value < MINIMUM_FEE) {
            revert Errors.SablierMerkleBase_InsufficientFeePayment(msg.value, MINIMUM_FEE);
        }

        // Check: the index has not been claimed.
        if (_claimedBitMap.get(index)) {
            revert Errors.SablierMerkleBase_StreamClaimed(index);
        }

        // Generate the Merkle tree leaf by hashing the corresponding parameters. Hashing twice prevents second
        // preimage attacks.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, recipient, amount))));

        // Check: the input claim is included in the Merkle tree.
        if (!MerkleProof.verify(merkleProof, MERKLE_ROOT, leaf)) {
            revert Errors.SablierMerkleBase_InvalidProof();
        }

        // Effect: set the `_firstClaimTime` if its zero.
        if (_firstClaimTime == 0) {
            _firstClaimTime = uint40(block.timestamp);
        }

        // Effect: mark the index as claimed.
        _claimedBitMap.set(index);

        // Call the internal virtual function.
        _claim(index, recipient, amount);
    }

    /// @inheritdoc ISablierMerkleBase
    function clawback(address to, uint128 amount) external override onlyAdmin {
        // Check: current timestamp is over the grace period and the campaign has not expired.
        if (_hasGracePeriodPassed() && !hasExpired()) {
            revert Errors.SablierMerkleBase_ClawbackNotAllowed({
                blockTimestamp: block.timestamp,
                expiration: EXPIRATION,
                firstClaimTime: _firstClaimTime
            });
        }

        // Effect: transfer the tokens to the provided address.
        TOKEN.safeTransfer({ to: to, value: amount });

        // Log the clawback.
        emit Clawback(admin, to, amount);
    }

    /// @inheritdoc ISablierMerkleBase
    function collectFees(address factoryAdmin) external override returns (uint256 feeAmount) {
        // Check: the caller is the FACTORY.
        if (msg.sender != FACTORY) {
            revert Errors.SablierMerkleBase_CallerNotFactory(FACTORY, msg.sender);
        }

        feeAmount = address(this).balance;

        // Effect: transfer the fees to the factory admin.
        (bool success,) = factoryAdmin.call{ value: feeAmount }("");

        // Revert if the call failed.
        if (!success) {
            revert Errors.SablierMerkleBase_FeeTransferFail(factoryAdmin, feeAmount);
        }
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

    /// @dev This function is implemented by child contracts, so the logic varies depending on the model.
    function _claim(uint256 index, address recipient, uint128 amount) internal virtual;
}
