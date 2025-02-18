// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";

import { Adminable } from "@sablier/lockup/src/abstracts/Adminable.sol";

import { ISablierMerkleBase } from "./interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactory } from "./interfaces/ISablierMerkleFactory.sol";
import { ISablierMerkleInstant } from "./interfaces/ISablierMerkleInstant.sol";
import { ISablierMerkleLL } from "./interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLT } from "./interfaces/ISablierMerkleLT.sol";
import { ISablierMerkleVCA } from "./interfaces/ISablierMerkleVCA.sol";
import { SablierMerkleInstant } from "./SablierMerkleInstant.sol";
import { SablierMerkleLL } from "./SablierMerkleLL.sol";
import { SablierMerkleLT } from "./SablierMerkleLT.sol";
import { SablierMerkleVCA } from "./SablierMerkleVCA.sol";
import { MerkleFactory, MerkleInstant, MerkleLL, MerkleLT, MerkleVCA } from "./types/DataTypes.sol";

/*

███████╗ █████╗ ██████╗ ██╗     ██╗███████╗██████╗
██╔════╝██╔══██╗██╔══██╗██║     ██║██╔════╝██╔══██╗
███████╗███████║██████╔╝██║     ██║█████╗  ██████╔╝
╚════██║██╔══██║██╔══██╗██║     ██║██╔══╝  ██╔══██╗
███████║██║  ██║██████╔╝███████╗██║███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝╚══════╝╚═╝  ╚═╝

███╗   ███╗███████╗██████╗ ██╗  ██╗██╗     ███████╗    ███████╗ █████╗  ██████╗████████╗ ██████╗ ██████╗ ██╗   ██╗
████╗ ████║██╔════╝██╔══██╗██║ ██╔╝██║     ██╔════╝    ██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
██╔████╔██║█████╗  ██████╔╝█████╔╝ ██║     █████╗      █████╗  ███████║██║        ██║   ██║   ██║██████╔╝ ╚████╔╝
██║╚██╔╝██║██╔══╝  ██╔══██╗██╔═██╗ ██║     ██╔══╝      ██╔══╝  ██╔══██║██║        ██║   ██║   ██║██╔══██╗  ╚██╔╝
██║ ╚═╝ ██║███████╗██║  ██║██║  ██╗███████╗███████╗    ██║     ██║  ██║╚██████╗   ██║   ╚██████╔╝██║  ██║   ██║
╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝

*/

/// @title SablierMerkleFactory
/// @notice See the documentation in {ISablierMerkleFactory}.
contract SablierMerkleFactory is
    ISablierMerkleFactory, // 1 inherited components
    Adminable // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactory
    uint256 public override minimumFee;

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
    function getCustomFee(address campaignCreator) external view override returns (MerkleFactory.CustomFee memory) {
        return _customFees[campaignCreator];
    }

    /// @inheritdoc ISablierMerkleFactory
    function getFee(address campaignCreator) external view returns (uint256) {
        return _getFee(campaignCreator);
    }

    /// @inheritdoc ISablierMerkleFactory
    function isPercentagesSum100(MerkleLT.TrancheWithPercentage[] calldata tranches)
        external
        pure
        override
        returns (bool result)
    {
        uint256 totalPercentage;
        for (uint256 i = 0; i < tranches.length; ++i) {
            totalPercentage += tranches[i].unlockPercentage.unwrap();
        }
        return totalPercentage == uUNIT;
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
        MerkleInstant.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleInstant merkleInstant)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleInstant contract with CREATE2.
        merkleInstant = new SablierMerkleInstant{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleInstant contract, including some metadata that is not stored on-chain.
        emit CreateMerkleInstant({
            merkleInstant: merkleInstant,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender)
        });
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleLL(
        MerkleLL.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLL merkleLL)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleLL contract with CREATE2.
        merkleLL = new SablierMerkleLL{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleLL contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLL({
            merkleLL: merkleLL,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender)
        });
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleLT(
        MerkleLT.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        override
        returns (ISablierMerkleLT merkleLT)
    {
        // Calculate the sum of percentages and durations across all tranches.
        uint256 count = params.tranchesWithPercentages.length;
        uint256 totalDuration;
        for (uint256 i = 0; i < count; ++i) {
            unchecked {
                // Safe to use `unchecked` because its only used in the event.
                totalDuration += params.tranchesWithPercentages[i].duration;
            }
        }

        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleLT contract with CREATE2.
        merkleLT = new SablierMerkleLT{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleLT contract, including some metadata that is not stored on-chain.
        emit CreateMerkleLT({
            merkleLT: merkleLT,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            totalDuration: totalDuration,
            fee: _getFee(msg.sender)
        });
    }

    /// @inheritdoc ISablierMerkleFactory
    function createMerkleVCA(
        MerkleVCA.ConstructorParams memory params,
        uint256 aggregateAmount,
        uint256 recipientCount
    )
        external
        returns (ISablierMerkleVCA merkleVCA)
    {
        // Hash the parameters to generate a salt.
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, abi.encode(params)));

        // Deploy the MerkleVCA contract with CREATE2.
        merkleVCA = new SablierMerkleVCA{ salt: salt }({ params: params, campaignCreator: msg.sender });

        // Log the creation of the MerkleVCA contract, including some metadata that is not stored on-chain.
        emit CreateMerkleVCA({
            merkleVCA: merkleVCA,
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: recipientCount,
            fee: _getFee(msg.sender)
        });
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
    function setMinimumFee(uint256 newFee) external override onlyAdmin {
        // Effect: update the minimum fee.
        minimumFee = newFee;

        emit SetMinimumFee({ admin: msg.sender, minimumFee: newFee });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the fee for the provided campaign creator, using the minimum fee if no custom fee is set.
    function _getFee(address campaignCreator) private view returns (uint256) {
        return _customFees[campaignCreator].enabled ? _customFees[campaignCreator].fee : minimumFee;
    }
}
