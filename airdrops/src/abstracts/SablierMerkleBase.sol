// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";

import { ISablierMerkleBase } from "./../interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "./../interfaces/ISablierMerkleFactoryBase.sol";
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
    address public immutable override ORACLE;

    /// @inheritdoc ISablierMerkleBase
    IERC20 public immutable override TOKEN;

    /// @inheritdoc ISablierMerkleBase
    string public override campaignName;

    /// @inheritdoc ISablierMerkleBase
    string public override ipfsCID;

    /// @inheritdoc ISablierMerkleBase
    uint256 public override minimumFee;

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
        EXPIRATION = expiration;
        FACTORY = msg.sender;
        MERKLE_ROOT = merkleRoot;
        ORACLE = ISablierMerkleFactoryBase(FACTORY).oracle();
        TOKEN = token;
        campaignName = _campaignName;
        ipfsCID = _ipfsCID;
        minimumFee = ISablierMerkleFactoryBase(FACTORY).getFee(campaignCreator);
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

    /// @inheritdoc ISablierMerkleBase
    function minimumFeeInWei() external view override returns (uint256) {
        return _minimumFeeInWei();
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

        // Calculate the minimum claim fee in wei.
        uint256 minClaimFee = _minimumFeeInWei();

        // Check: `msg.value` is more than the minimum claim fee.
        if (msg.value < minClaimFee) {
            revert Errors.SablierMerkleBase_InsufficientFeePayment(msg.value, minClaimFee);
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

    /// @inheritdoc ISablierMerkleBase
    function lowerMinimumFee(uint256 newFee) external override {
        // Retrieve the factory admin.
        address factoryAdmin = ISablierMerkleFactoryBase(FACTORY).admin();

        // Check: the caller is the factory admin.
        if (factoryAdmin != msg.sender) {
            revert Errors.SablierMerkleBase_CallerNotFactoryAdmin({ factoryAdmin: factoryAdmin, caller: msg.sender });
        }

        uint256 currentFee = minimumFee;

        // Check: the new fee is less than the current fee.
        if (newFee >= currentFee) {
            revert Errors.SablierMerkleBase_NewFeeHigher(currentFee, newFee);
        }

        // Effect: update the minimum fee to new value.
        minimumFee = newFee;

        // Log the event.
        emit LowerMinimumFee(factoryAdmin, newFee, currentFee);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _minimumFeeInWei() internal view returns (uint256) {
        // If the oracle is not set, return 0.
        if (ORACLE == address(0)) {
            return 0;
        }

        // If the minimum fee is 0, skip the calculations.
        if (minimumFee == 0) {
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
        return minimumFee * 1e18 / price8D;
    }

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
