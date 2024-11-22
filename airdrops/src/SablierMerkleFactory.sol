// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";

import { Adminable } from "@sablier/lockup/abstracts/Adminable.sol";
import { ISablierLockup } from "@sablier/lockup/interfaces/ISablierLockup.sol";

import { ISablierMerkleBase } from "./interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "./interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { SablierMerkleInstant } from "./SablierMerkleInstant.sol";
import { SablierMerkleLL } from "./SablierMerkleLL.sol";
import { SablierMerkleLT } from "./SablierMerkleLT.sol";
import { MerkleBase, MerkleFactory, MerkleLL, MerkleLT } from "./types/DataTypes.sol";

/// @title SablierMerkleFactory
/// @notice See the documentation in {ISablierMerkleFactory}.
contract SablierMerkleFactory is
    ISablierMerkleFactory, // 2 inherited components
    Adminable // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    uint256 public override defaultFee;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => MerkleFactory.CustomFee customFee) private _customFees;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    constructor(address initialAdmin) Adminable(initialAdmin) { }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        override
        returns (bool result)
    {
        uint64 totalPercentage;
        for (uint256 i = 0; i < tranches.length; ++i) {
            totalPercentage += tranches[i].unlockPercentage.unwrap();
        }
        return totalPercentage == uUNIT;
    }

    /// @inheritdoc ISablierMerkleFactory
    function customFee(address campaignCreator) external view override returns (MerkleFactory.CustomFee memory) {
        return _customFees[campaignCreator];
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    function collectFees(ISablierMerkleBase merkleBase) external override {
        // Effect: collect the fees from the MerkleBase contract.
        uint256 feeAmount = merkleBase.collectFees(admin);

        // Log the fee withdrawal.
        emit CollectFees({ admin: admin, merkleBase: merkleBase, feeAmount: feeAmount });
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleInstant(
        MerkleBase.ConstructorParams memory baseParams,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleInstant merkleInstant)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                baseParams.token,
                baseParams.expiration,
                baseParams.initialAdmin,
                abi.encode(baseParams.ipfsCID),
                baseParams.merkleRoot,
                bytes32(abi.encodePacked(baseParams.name))
            )
        );

        // Compute the fee for the user.
        uint256 fee = _computeFeeForUser(msg.sender);

        // Deploy the MerkleInstant contract with CREATE2.
        merkleInstant = new SablierMerkleInstant{ salt: salt }(baseParams, fee);

        // Log the creation of the MerkleInstant contract, including some metadata that is not stored on-chain.
        emit CreateMerkleInstant(merkleInstant, baseParams, aggregateAmount, recipientCount, fee);
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleLL(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        MerkleLL.Schedule memory schedule,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLL merkleLL)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                baseParams.token,
                baseParams.expiration,
                baseParams.initialAdmin,
                abi.encode(baseParams.ipfsCID),
                baseParams.merkleRoot,
                bytes32(abi.encodePacked(baseParams.name)),
                lockup,
                cancelable,
                transferable,
                abi.encode(schedule)
            )
        );

        // Compute the fee for the user.
        uint256 fee = _computeFeeForUser(msg.sender);

        // Deploy the MerkleLL contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }(baseParams, lockup, cancelable, transferable, schedule, fee);

        // Log the creation of the MerkleLL contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL(
            merkleLL, baseParams, lockup, cancelable, transferable, schedule, aggregateAmount, recipientCount, fee
        );
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleLT(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLT merkleLT)
    {
        // Calculate the sum of percentages and durations across all tranches.
        uint256 count = tranchesWithPercentages.length;
        uint256 totalDuration;
        for (uint256 i = 0; i < count; ++i) {
            unchecked {
                // Safe to use `unchecked` because its only used in the event.
                totalDuration += tranchesWithPercentages[i].duration;
            }
        }

        // Compute the fee for the user.
        uint256 fee = _computeFeeForUser(msg.sender);

        // Deploy the MerkleLT contract.
        merkleLT =
            _deployMerkleLT(baseParams, lockup, cancelable, transferable, streamStartTime, tranchesWithPercentages, fee);

        // Log the creation of the MerkleLT contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLT(
            merkleLT,
            baseParams,
            lockup,
            cancelable,
            transferable,
            streamStartTime,
            tranchesWithPercentages,
            totalDuration,
            aggregateAmount,
            recipientCount,
            fee
        );
    }

    /// @inheritdoc ISablierMerkleFactory
    function resetCustomFee(address campaignCreator) external override onlyAdmin {
        delete _customFees[campaignCreator];

        // Log the reset.
        emit ResetCustomFee({ admin: msg.sender, campaignCreator: campaignCreator });
    }

    /// @inheritdoc ISablierMerkleFactory
    function setCustomFee(address campaignCreator, uint256 newFee) external override onlyAdmin {
        MerkleFactory.CustomFee storage customFeeByUser = _customFees[campaignCreator];

        // Check: if the user is not in the custom fee list.
        if (!customFeeByUser.enabled) {
            customFeeByUser.enabled = true;
        }

        // Effect: update the custom fee for the given campaign creator.
        customFeeByUser.fee = newFee;

        // Log the update.
        emit SetCustomFee({ admin: msg.sender, campaignCreator: campaignCreator, customFee: newFee });
    }

    /// @inheritdoc ISablierMerkleFactory
    function setDefaultFee(uint256 defaultFee_) external override onlyAdmin {
        // Effect: update the default fee.
        defaultFee = defaultFee_;

        emit SetDefaultFee(msg.sender, defaultFee_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                           PRIVATE NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Computes the fee for the user, using the default fee if no custom fee is set.
    function _computeFeeForUser(address user) private view returns (uint256) {
        return _customFees[user].enabled ? _customFees[user].fee : defaultFee;
    }

    /// @notice Deploys a new MerkleLT contract with CREATE2.
    /// @dev We need a separate function to prevent the stack too deep error.
    function _deployMerkleLT(
        MerkleBase.ConstructorParams memory baseParams,
        ISablierLockup lockup,
        bool cancelable,
        bool transferable,
        uint40 streamStartTime,
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages,
        uint256 fee
    )
        private
        returns (ISablierMerkleLT merkleLT)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                baseParams.token,
                baseParams.expiration,
                baseParams.initialAdmin,
                abi.encode(baseParams.ipfsCID),
                baseParams.merkleRoot,
                bytes32(abi.encodePacked(baseParams.name)),
                lockup,
                cancelable,
                transferable,
                streamStartTime,
                abi.encode(tranchesWithPercentages)
            )
        );

        // Deploy the MerkleLT contract with CREATE2.
        merkleLT = new SablierMerkleLT{ salt: salt }(
            baseParams, lockup, cancelable, transferable, streamStartTime, tranchesWithPercentages, fee
        );
    }
}
