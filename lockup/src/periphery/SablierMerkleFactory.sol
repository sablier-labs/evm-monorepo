// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";

import { Adminable } from "../core/abstracts/Adminable.sol";
import { ISablierLockup } from "../core/interfaces/ISablierLockup.sol";

import { ISablierMerkleBase } from "./interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "./interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { Errors } from "./libraries/Errors.sol";
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
    uint256 public override defaultSablierFee;

    /// @dev A mapping of custom Sablier fees by user.
    mapping(address campaignCreator => MerkleFactory.SablierFeeByUser customFee) private _sablierFeeByUsers;

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
    function sablierFeeByUser(address campaignCreator)
        external
        view
        override
        returns (MerkleFactory.SablierFeeByUser memory)
    {
        return _sablierFeeByUsers[campaignCreator];
    }

    /*//////////////////////////////////////////////////////////////////////////
                         ADMIN-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    function resetSablierFeeByUser(address campaignCreator) external override onlyAdmin {
        delete _sablierFeeByUsers[campaignCreator];

        // Log the reset.
        emit ResetSablierFee({ admin: msg.sender, campaignCreator: campaignCreator });
    }

    /// @inheritdoc ISablierMerkleFactory
    function setDefaultSablierFee(uint256 defaultFee) external override onlyAdmin {
        // Effect: update the default Sablier fee.
        defaultSablierFee = defaultFee;

        emit SetDefaultSablierFee(msg.sender, defaultFee);
    }

    /// @inheritdoc ISablierMerkleFactory
    function setSablierFeeByUser(address campaignCreator, uint256 fee) external override onlyAdmin {
        MerkleFactory.SablierFeeByUser storage feeByUser = _sablierFeeByUsers[campaignCreator];

        // Check: if user does not belong to the custom fee list.
        if (!feeByUser.enabled) feeByUser.enabled = true;

        // Effect: update the Sablier fee for the given campaign creator.
        feeByUser.fee = fee;

        // Log the update.
        emit SetSablierFeeForUser({ admin: msg.sender, campaignCreator: campaignCreator, sablierFee: fee });
    }

    /// @inheritdoc ISablierMerkleFactory
    function withdrawFees(address payable to, ISablierMerkleBase merkleBase) external override onlyAdmin {
        // Check: the withdrawal address is not zero.
        if (to == address(0)) {
            revert Errors.SablierMerkleFactory_WithdrawToZeroAddress();
        }

        // Effect: call `withdrawFees` on the MerkleBase contract.
        uint256 fees = merkleBase.withdrawFees(to);

        // Log the withdrawal.
        emit WithdrawSablierFees({ admin: msg.sender, merkleBase: merkleBase, to: to, sablierFees: fees });
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

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
                baseParams.asset,
                baseParams.expiration,
                baseParams.initialAdmin,
                abi.encode(baseParams.ipfsCID),
                baseParams.merkleRoot,
                bytes32(abi.encodePacked(baseParams.name))
            )
        );

        // Compute the Sablier fee for the user.
        uint256 sablierFee = _computeSablierFeeForUser(msg.sender);

        // Deploy the MerkleInstant contract with CREATE2.
        merkleInstant = new SablierMerkleInstant{ salt: salt }(baseParams, sablierFee);

        // Log the creation of the MerkleInstant contract, including some metadata that is not stored on-chain.
        emit CreateMerkleInstant(merkleInstant, baseParams, aggregateAmount, recipientCount, sablierFee);
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
                baseParams.asset,
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

        // Compute the Sablier fee for the user.
        uint256 sablierFee = _computeSablierFeeForUser(msg.sender);

        // Deploy the MerkleLL contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }(baseParams, lockup, cancelable, transferable, schedule, sablierFee);

        // Log the creation of the MerkleLL contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL(
            merkleLL,
            baseParams,
            lockup,
            cancelable,
            transferable,
            schedule,
            aggregateAmount,
            recipientCount,
            sablierFee
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

        // Compute the Sablier fee for the user.
        uint256 sablierFee = _computeSablierFeeForUser(msg.sender);

        // Deploy the MerkleLT contract.
        merkleLT = _deployMerkleLT(
            baseParams, lockup, cancelable, transferable, streamStartTime, tranchesWithPercentages, sablierFee
        );

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
            sablierFee
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                           PRIVATE NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Computes the Sablier fee for the user, use the default fee if not enabled.
    function _computeSablierFeeForUser(address user) private view returns (uint256) {
        return _sablierFeeByUsers[user].enabled ? _sablierFeeByUsers[user].fee : defaultSablierFee;
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
        uint256 sablierFee
    )
        private
        returns (ISablierMerkleLT merkleLT)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(
            abi.encodePacked(
                msg.sender,
                baseParams.asset,
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
            baseParams, lockup, cancelable, transferable, streamStartTime, tranchesWithPercentages, sablierFee
        );
    }
}
