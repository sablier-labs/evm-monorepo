// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { Adminable } from "@sablier/lockup/src/abstracts/Adminable.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "../interfaces/ISablierMerkleFactoryBase.sol";
import { MerkleFactory } from "../types/DataTypes.sol";

/// @title SablierMerkleFactoryBase
/// @notice See the documentation in {ISablierMerkleFactoryBase}.
abstract contract SablierMerkleFactoryBase is
    ISablierMerkleFactoryBase, // 1 inherited component
    Adminable // 1 inherited component
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    uint256 public override minimumFee;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => MerkleFactory.CustomFee customFee) private _customFees;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialMinimumFee The initial minimum fee charged for claiming an airdrop.
    constructor(address initialAdmin, uint256 initialMinimumFee) Adminable(initialAdmin) {
        minimumFee = initialMinimumFee;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    function getCustomFee(address campaignCreator) external view override returns (MerkleFactory.CustomFee memory) {
        return _customFees[campaignCreator];
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function getFee(address campaignCreator) external view returns (uint256) {
        return _getFee(campaignCreator);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierMerkleFactoryBase
    function collectFees(ISablierMerkleBase merkleBase) external override {
        // Effect: collect the fees from the MerkleBase contract.
        uint256 feeAmount = merkleBase.collectFees(admin);

        // Log the fee withdrawal.
        emit CollectFees({ admin: admin, merkleBase: merkleBase, feeAmount: feeAmount });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function resetCustomFee(address campaignCreator) external override onlyAdmin {
        delete _customFees[campaignCreator];

        // Log the reset.
        emit ResetCustomFee({ admin: msg.sender, campaignCreator: campaignCreator });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
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

    /// @inheritdoc ISablierMerkleFactoryBase
    function setMinimumFee(uint256 newFee) external override onlyAdmin {
        // Effect: update the minimum fee.
        minimumFee = newFee;

        emit SetMinimumFee({ admin: msg.sender, minimumFee: newFee });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the fee for the provided campaign creator, using the minimum fee if no custom fee is set.
    function _getFee(address campaignCreator) internal view returns (uint256) {
        return _customFees[campaignCreator].enabled ? _customFees[campaignCreator].fee : minimumFee;
    }
}
