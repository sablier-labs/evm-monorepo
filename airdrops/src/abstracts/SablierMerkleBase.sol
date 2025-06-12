// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";
import { ISablierFactoryMerkleBase } from "./../interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierMerkleBase } from "./../interfaces/ISablierMerkleBase.sol";
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
    uint40 public immutable override CAMPAIGN_START_TIME;

    /// @inheritdoc ISablierMerkleBase
    uint40 public immutable override EXPIRATION;

    /// @inheritdoc ISablierMerkleBase
    ISablierFactoryMerkleBase public immutable override FACTORY;

    /// @inheritdoc ISablierMerkleBase
    bool public constant override IS_SABLIER_MERKLE = true;

    /// @inheritdoc ISablierMerkleBase
    bytes32 public immutable override MERKLE_ROOT;

    /// @inheritdoc ISablierMerkleBase
    address public immutable override ORACLE;

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
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Constructs the contract by initializing the immutable state variables.
    constructor(
        address campaignCreator,
        string memory campaignName_,
        uint40 campaignStartTime,
        uint40 expiration,
        address initialAdmin,
        string memory ipfsCID_,
        bytes32 merkleRoot,
        IERC20 token
    )
        Adminable(initialAdmin)
    {
        CAMPAIGN_START_TIME = campaignStartTime;
        EXPIRATION = expiration;
        FACTORY = ISablierFactoryMerkleBase(msg.sender);
        MERKLE_ROOT = merkleRoot;
        ORACLE = FACTORY.oracle();
        TOKEN = token;
        campaignName = campaignName_;
        ipfsCID = ipfsCID_;
        minFeeUSD = FACTORY.minFeeUSDFor(campaignCreator);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleBase
    function calculateMinFeeWei() external view override returns (uint256) {
        return _calculateMinFeeWei();
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
        // Safe Interaction: retrieve the factory admin.
        address factoryAdmin = FACTORY.admin();

        // Check: the caller is the factory admin.
        if (factoryAdmin != msg.sender) {
            revert Errors.SablierMerkleBase_CallerNotFactoryAdmin({ factoryAdmin: factoryAdmin, caller: msg.sender });
        }

        uint256 currentMinFeeUSD = minFeeUSD;

        // Check: the new min USD fee is lower than the current min fee USD.
        if (newMinFeeUSD >= currentMinFeeUSD) {
            revert Errors.SablierMerkleBase_NewMinFeeUSDNotLower(currentMinFeeUSD, newMinFeeUSD);
        }

        // Effect: update the min USD fee.
        minFeeUSD = newMinFeeUSD;

        // Log the event.
        emit LowerMinFeeUSD({
            factoryAdmin: factoryAdmin,
            newMinFeeUSD: newMinFeeUSD,
            previousMinFeeUSD: currentMinFeeUSD
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _calculateMinFeeWei() private view returns (uint256) {
        // If the oracle is not set, return 0.
        if (ORACLE == address(0)) {
            return 0;
        }

        // If the min USD fee is 0, skip the calculations.
        if (minFeeUSD == 0) {
            return 0;
        }

        // Interactions: query the oracle price and the time at which it was updated.
        (, int256 price,, uint256 updatedAt,) = AggregatorV3Interface(ORACLE).latestRoundData();

        // If the price is not greater than 0, skip the calculations.
        if (price <= 0) {
            return 0;
        }

        // Due to reorgs and latency issues, the oracle can have an `updatedAt` timestamp that is in the future. In
        // this case, we ignore the price and return 0.
        if (block.timestamp < updatedAt) {
            return 0;
        }

        // If the oracle hasn't been updated in the last 24 hours, we ignore the price and return 0. This is a safety
        // check to avoid using outdated prices.
        unchecked {
            if (block.timestamp - updatedAt > 24 hours) {
                return 0;
            }
        }

        // Interactions: query the oracle decimals.
        uint8 oracleDecimals = AggregatorV3Interface(ORACLE).decimals();

        // Adjust the price so that it has 8 decimals.
        uint256 price8D;
        if (oracleDecimals == 8) {
            price8D = uint256(price);
        } else if (oracleDecimals < 8) {
            price8D = uint256(price) * 10 ** (8 - oracleDecimals);
        } else {
            price8D = uint256(price) / 10 ** (oracleDecimals - 8);
        }

        // Multiply by 10^18 because the native token is assumed to have 18 decimals.
        return minFeeUSD * 1e18 / price8D;
    }

    /// @notice Returns a flag indicating whether the grace period has passed.
    /// @dev The grace period is 7 days after the first claim.
    function _hasGracePeriodPassed() private view returns (bool) {
        return firstClaimTime > 0 && block.timestamp > firstClaimTime + 7 days;
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

        // Calculate the min fee in wei.
        uint256 minFeeWei = _calculateMinFeeWei();

        uint256 feePaid = msg.value;

        // Check: the min fee was paid.
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

        // Interaction: transfer the fee to factory if it's greater than 0.
        if (feePaid > 0) {
            (bool success,) = address(FACTORY).call{ value: feePaid }("");

            // Revert if the transfer failed.
            if (!success) {
                revert Errors.SablierMerkleBase_FeeTransferFailed(address(FACTORY), feePaid);
            }
        }
    }
}
