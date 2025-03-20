// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { Adminable } from "@sablier/evm-utils/src/Adminable.sol";

import { ISablierMerkleBase } from "../interfaces/ISablierMerkleBase.sol";
import { ISablierMerkleFactoryBase } from "../interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "../libraries/Errors.sol";
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
    uint256 public constant override MAX_FEE = 100e8;

    /// @inheritdoc ISablierMerkleFactoryBase
    address public override oracle;

    /// @inheritdoc ISablierMerkleFactoryBase
    uint256 public override minimumFee;

    /// @inheritdoc ISablierMerkleFactoryBase
    address public override nativeToken;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => MerkleFactory.CustomFee customFee) private _customFees;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialMinimumFee The initial minimum fee charged for claiming an airdrop.
    /// @param initialOracle The initial oracle contract address.
    constructor(address initialAdmin, uint256 initialMinimumFee, address initialOracle) Adminable(initialAdmin) {
        minimumFee = initialMinimumFee;

        if (initialOracle != address(0)) {
            _setOracle(initialOracle);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                           USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

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

        // Check: the new fee is not greater than `MAX_FEE`.
        if (newFee > MAX_FEE) {
            revert Errors.SablierMerkleFactoryBase_MaximumFeeExceeded(newFee, MAX_FEE);
        }

        // Effect: enable the custom fee for the user if it is not already enabled.
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
        // Check: the new fee is not greater than `MAX_FEE`.
        if (newFee > MAX_FEE) {
            revert Errors.SablierMerkleFactoryBase_MaximumFeeExceeded(newFee, MAX_FEE);
        }

        // Effect: update the minimum fee.
        minimumFee = newFee;

        // Log the update.
        emit SetMinimumFee({ admin: msg.sender, minimumFee: newFee });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setNativeToken(address newNativeToken) external override onlyAdmin {
        // Check: provided token is not zero address.
        if (newNativeToken == address(0)) {
            revert Errors.SablierMerkleFactoryBase_NativeTokenZeroAddress();
        }

        // Check: native token is not set.
        if (nativeToken != address(0)) {
            revert Errors.SablierMerkleFactoryBase_NativeTokenAlreadySet(nativeToken);
        }

        // Effect: set the native token.
        nativeToken = newNativeToken;

        // Log the update.
        emit SetNativeToken({ admin: msg.sender, nativeToken: newNativeToken });
    }

    /// @inheritdoc ISablierMerkleFactoryBase
    function setOracle(address newOracle) external override onlyAdmin {
        address currentOracle = oracle;

        _setOracle(newOracle);

        // Log the update.
        emit SetOracle({ admin: msg.sender, newOracle: newOracle, previousOracle: currentOracle });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the fee for the provided campaign creator, using the minimum fee if no custom fee is set.
    function _getFee(address campaignCreator) internal view returns (uint256) {
        return _customFees[campaignCreator].enabled ? _customFees[campaignCreator].fee : minimumFee;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks that the provided token is not the native token.
    /// @dev Reverts if the provided token is the native token.
    function _forbidNativeToken(address token) internal view {
        if (token == nativeToken) {
            revert Errors.SablierMerkleFactoryBase_ForbidNativeToken(token);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _setOracle(address newOracle) private {
        // Check: oracle implements the `latestRoundData` function.
        if (newOracle != address(0)) {
            AggregatorV3Interface(newOracle).latestRoundData();
        }

        // Effect: update the oracle.
        oracle = newOracle;
    }
}
