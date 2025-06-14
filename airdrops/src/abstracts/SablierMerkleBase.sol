// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { ISablierMerkleBase } from "./../interfaces/ISablierMerkleBase.sol";
import { Errors } from "./../libraries/Errors.sol";
import { SignatureHash } from "./../libraries/SignatureHash.sol";

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
    uint40 public immutable override CAMPAIGN_START_TIME;

    /// @inheritdoc ISablierMerkleBase
    address public immutable override COMPTROLLER;

    /// @inheritdoc ISablierMerkleBase
    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @inheritdoc ISablierMerkleBase
    uint40 public immutable override EXPIRATION;

    /// @inheritdoc ISablierMerkleBase
    bool public constant override IS_SABLIER_MERKLE = true;

    /// @inheritdoc ISablierMerkleBase
    bytes32 public immutable override MERKLE_ROOT;

    /// @inheritdoc ISablierMerkleBase
    IERC20 public immutable override TOKEN;

    /// @inheritdoc ISablierMerkleBase
    string public override campaignName;

    /// @inheritdoc ISablierMerkleBase
    uint40 public override firstClaimTime;

    /// @inheritdoc ISablierMerkleBase
    string public override ipfsCID;

    /// @inheritdoc ISablierMerkleBase
    uint256 public override minFeeUSD;

    /// @dev Packed booleans that record the history of claims.
    BitMaps.BitMap internal _claimedBitMap;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Modifier to check that `to` is not zero address.
    modifier notZeroAddress(address to) {
        _revertIfToZeroAddress(to);

        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructs the contract by initializing the immutable state variables.
    constructor(
        address campaignCreator,
        string memory campaignName_,
        uint40 campaignStartTime,
        address comptroller,
        uint40 expiration,
        address initialAdmin,
        string memory ipfsCID_,
        bytes32 merkleRoot,
        IERC20 token
    )
        Adminable(initialAdmin)
    {
        // Compute the domain separator to be used for claiming using an EIP-712 or EIP-1271 signature.
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(SignatureHash.DOMAIN_TYPEHASH, SignatureHash.PROTOCOL_NAME, block.chainid, address(this))
        );

        CAMPAIGN_START_TIME = campaignStartTime;
        COMPTROLLER = comptroller;
        EXPIRATION = expiration;
        MERKLE_ROOT = merkleRoot;
        TOKEN = token;

        campaignName = campaignName_;
        ipfsCID = ipfsCID_;
        minFeeUSD = ISablierComptroller(COMPTROLLER).getAirdropsMinFeeUSDFor(campaignCreator);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    function hasClaimed(uint256 index) public view override returns (bool) {
        return _claimedBitMap.get(index);
    }

    /// @inheritdoc ISablierMerkleBase
    function hasExpired() public view override returns (bool) {
        return EXPIRATION > 0 && EXPIRATION <= block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    function clawback(address to, uint128 amount) external override onlyAdmin {
        // Check: the grace period has passed and the campaign has not expired.
        if (_hasGracePeriodPassed() && !hasExpired()) {
            revert Errors.SablierMerkleBase_ClawbackNotAllowed({
                blockTimestamp: block.timestamp,
                expiration: EXPIRATION,
                firstClaimTime: firstClaimTime
            });
        }

        // Effect: transfer the tokens to the provided address.
        TOKEN.safeTransfer({ to: to, value: amount });

        // Log the clawback.
        emit Clawback({ admin: admin, to: to, amount: amount });
    }

    /// @inheritdoc ISablierMerkleBase
    function lowerMinFeeUSD(uint256 newMinFeeUSD) external override {
        // Check: the caller is the comptroller.
        if (COMPTROLLER != msg.sender) {
            revert Errors.SablierMerkleBase_CallerNotComptroller(COMPTROLLER, msg.sender);
        }

        uint256 currentMinFeeUSD = minFeeUSD;

        // Check: the new min USD fee is lower than the current min fee USD.
        if (newMinFeeUSD >= currentMinFeeUSD) {
            revert Errors.SablierMerkleBase_NewMinFeeUSDNotLower(currentMinFeeUSD, newMinFeeUSD);
        }

        // Effect: update the min USD fee.
        minFeeUSD = newMinFeeUSD;

        // Log the event.
        emit LowerMinFeeUSD({ comptroller: COMPTROLLER, newMinFeeUSD: newMinFeeUSD, previousMinFeeUSD: currentMinFeeUSD });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Verifies the signature against the provided parameters. It supports both EIP-712 and EIP-1271 signatures.
    function _checkSignature(
        uint256 index,
        address recipient,
        address to,
        uint128 amount,
        bytes calldata signature
    )
        internal
        view
    {
        // Encode the claim parameters using claim type hash and hash it.
        bytes32 claimHash = keccak256(abi.encode(SignatureHash.CLAIM_TYPEHASH, index, recipient, to, amount));

        // Returns the keccak256 digest of the claim parameters using claim hash and the domain separator.
        bytes32 digest = MessageHashUtils.toTypedDataHash({ domainSeparator: DOMAIN_SEPARATOR, structHash: claimHash });

        // If recipient is an EOA, `isValidSignatureNow` recovers the signer using ECDSA from the signature and the
        // digest. It returns true if the recovered signer matches the recipient. If the recipient is a contract,
        // `isValidSignatureNow` checks if the recipient implements the `IERC1271` interface and returns the magic value
        // as per EIP-1271 for the given digest and signature.
        bool isSignatureValid =
            SignatureChecker.isValidSignatureNow({ signer: recipient, hash: digest, signature: signature });

        // Check: `isSignatureValid` is true.
        if (!isSignatureValid) {
            revert Errors.SablierMerkleBase_InvalidSignature();
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns a flag indicating whether the grace period has passed.
    /// @dev The grace period is 7 days after the first claim.
    function _hasGracePeriodPassed() private view returns (bool) {
        return firstClaimTime > 0 && block.timestamp > firstClaimTime + 7 days;
    }

    /// @dev This function checks if `to` is zero address.
    function _revertIfToZeroAddress(address to) private pure {
        if (to == address(0)) {
            revert Errors.SablierMerkleBase_ToZeroAddress();
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                         INTERNAL STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _preProcessClaim(
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] calldata merkleProof
    )
        internal
    {
        // Check: the campaign start time is not in the future.
        if (CAMPAIGN_START_TIME > block.timestamp) {
            revert Errors.SablierMerkleBase_CampaignNotStarted({
                blockTimestamp: block.timestamp,
                campaignStartTime: CAMPAIGN_START_TIME
            });
        }

        // Check: the campaign has not expired.
        if (hasExpired()) {
            revert Errors.SablierMerkleBase_CampaignExpired({ blockTimestamp: block.timestamp, expiration: EXPIRATION });
        }

        // Safe interaction: calculate the min fee in wei.
        uint256 minFeeWei = ISablierComptroller(COMPTROLLER).calculateMinFeeWei(minFeeUSD);

        uint256 feePaid = msg.value;

        // Check: the min fee is paid.
        if (feePaid < minFeeWei) {
            revert Errors.SablierMerkleBase_InsufficientFeePayment(feePaid, minFeeWei);
        }

        // Check: the index has not been claimed.
        if (_claimedBitMap.get(index)) {
            revert Errors.SablierMerkleBase_IndexClaimed(index);
        }

        // Generate the Merkle tree leaf. Hashing twice prevents second preimage attacks.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, recipient, amount))));

        // Check: the input claim is included in the Merkle tree.
        if (!MerkleProof.verify(merkleProof, MERKLE_ROOT, leaf)) {
            revert Errors.SablierMerkleBase_InvalidProof();
        }

        // Effect: if this is the first time claim, take a record of the block timestamp.
        if (firstClaimTime == 0) {
            firstClaimTime = uint40(block.timestamp);
        }

        // Effect: mark the index as claimed.
        _claimedBitMap.set(index);

        // Interaction: transfer the fee to comptroller if it's greater than 0.
        if (feePaid > 0) {
            (bool success,) = COMPTROLLER.call{ value: feePaid }("");

            // Revert if the transfer failed.
            if (!success) {
                revert Errors.SablierMerkleBase_FeeTransferFailed(COMPTROLLER, feePaid);
            }
        }
    }
}
