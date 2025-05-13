// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { RoleAdminable } from "@sablier/evm-utils/src/RoleAdminable.sol";
import { ISablierFactoryMerkleBase } from "./../interfaces/ISablierFactoryMerkleBase.sol";
import { ISablierMerkleBase } from "./../interfaces/ISablierMerkleBase.sol";
import { Errors } from "./../libraries/Errors.sol";
import { FactoryMerkle } from "./../types/DataTypes.sol";

/// @title SablierFactoryMerkleBase
/// @notice See the documentation in {ISablierFactoryMerkleBase}.
abstract contract SablierFactoryMerkleBase is
    ISablierFactoryMerkleBase, // 2 inherited components
    RoleAdminable // 3 inherited components
{
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleBase
    uint256 public constant override MAX_FEE_USD = 100e8;

    /// @inheritdoc ISablierFactoryMerkleBase
    address public override oracle;

    /// @inheritdoc ISablierFactoryMerkleBase
    uint256 public override minFeeUSD;

    /// @inheritdoc ISablierFactoryMerkleBase
    address public override nativeToken;

    /// @dev A mapping of custom fees mapped by campaign creator addresses.
    mapping(address campaignCreator => FactoryMerkle.CustomFeeUSD customFeeUSD) private _customFeesUSD;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialMinFeeUSD The initial min USD fee charged for claiming an airdrop.
    /// @param initialOracle The initial oracle contract address.
    constructor(address initialAdmin, uint256 initialMinFeeUSD, address initialOracle) RoleAdminable(initialAdmin) {
        minFeeUSD = initialMinFeeUSD;

        if (initialOracle != address(0)) {
            _setOracle(initialOracle);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleBase
    function minFeeUSDFor(address campaignCreator) external view returns (uint256) {
        return _minFeeUSDFor(campaignCreator);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierFactoryMerkleBase
    function collectFees(ISablierMerkleBase campaign, address feeRecipient) external override {
        // Check: if `msg.sender` has neither the {IRoleAdminable.FEE_COLLECTOR_ROLE} role nor is the contract admin,
        // then `feeRecipient` must be the admin address.
        bool hasRoleOrIsAdmin = _hasRoleOrIsAdmin({ role: FEE_COLLECTOR_ROLE, account: msg.sender });
        if (!hasRoleOrIsAdmin && feeRecipient != admin) {
            revert Errors.SablierMerkleFactoryBase_FeeRecipientNotAdmin({ feeRecipient: feeRecipient, admin: admin });
        }

        // Effect: collect the fees from the campaign contract.
        uint256 feeAmount = campaign.collectFees(feeRecipient);

        // Log the fee withdrawal.
        emit CollectFees({ admin: admin, campaign: campaign, feeRecipient: feeRecipient, feeAmount: feeAmount });
    }

    /// @inheritdoc ISablierFactoryMerkleBase
    function disableCustomFeeUSD(address campaignCreator) external override onlyRole(FEE_MANAGEMENT_ROLE) {
        delete _customFeesUSD[campaignCreator];

        // Log the reset.
        emit DisableCustomFeeUSD({ admin: admin, campaignCreator: campaignCreator });
    }

    /// @inheritdoc ISablierFactoryMerkleBase
    function setCustomFeeUSD(
        address campaignCreator,
        uint256 customFeeUSD
    )
        external
        override
        onlyRole(FEE_MANAGEMENT_ROLE)
    {
        FactoryMerkle.CustomFeeUSD storage customFee = _customFeesUSD[campaignCreator];

        // Check: the new fee is not greater than the maximum allowed.
        if (customFeeUSD > MAX_FEE_USD) {
            revert Errors.SablierFactoryMerkleBase_MaxFeeUSDExceeded(customFeeUSD, MAX_FEE_USD);
        }

        // Effect: enable the custom fee for the user if it is not already enabled.
        if (!customFee.enabled) {
            customFee.enabled = true;
        }

        // Effect: update the custom fee for the provided campaign creator.
        customFee.fee = customFeeUSD;

        // Log the update.
        emit SetCustomFeeUSD({ admin: admin, campaignCreator: campaignCreator, customFeeUSD: customFeeUSD });
    }

    /// @inheritdoc ISablierFactoryMerkleBase
    function setMinFeeUSD(uint256 newMinFeeUSD) external override onlyRole(FEE_MANAGEMENT_ROLE) {
        // Check: the new fee is not greater than the maximum allowed.
        if (newMinFeeUSD > MAX_FEE_USD) {
            revert Errors.SablierFactoryMerkleBase_MaxFeeUSDExceeded(newMinFeeUSD, MAX_FEE_USD);
        }

        // Effect: update the min USD fee.
        uint256 currentMinFeeUSD = minFeeUSD;
        minFeeUSD = newMinFeeUSD;

        // Log the update.
        emit SetMinFeeUSD({ admin: admin, newMinFeeUSD: newMinFeeUSD, previousMinFeeUSD: currentMinFeeUSD });
    }

    /// @inheritdoc ISablierFactoryMerkleBase
    function setNativeToken(address newNativeToken) external override onlyAdmin {
        // Check: provided token is not zero address.
        if (newNativeToken == address(0)) {
            revert Errors.SablierFactoryMerkleBase_NativeTokenZeroAddress();
        }

        // Check: native token is not set.
        if (nativeToken != address(0)) {
            revert Errors.SablierFactoryMerkleBase_NativeTokenAlreadySet(nativeToken);
        }

        // Effect: set the native token.
        nativeToken = newNativeToken;

        // Log the update.
        emit SetNativeToken({ admin: msg.sender, nativeToken: newNativeToken });
    }

    /// @inheritdoc ISablierFactoryMerkleBase
    function setOracle(address newOracle) external override onlyAdmin {
        address currentOracle = oracle;

        // Effects: set the new oracle.
        _setOracle(newOracle);

        // Log the update.
        emit SetOracle({ admin: msg.sender, newOracle: newOracle, previousOracle: currentOracle });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks that the provided token is not the native token.
    /// @dev Reverts if the provided token is the native token.
    function _forbidNativeToken(address token) internal view {
        if (token == nativeToken) {
            revert Errors.SablierFactoryMerkleBase_ForbidNativeToken(token);
        }
    }

    /// @dev See the documentation for the user-facing functions that call this internal function.
    function _minFeeUSDFor(address campaignCreator) internal view returns (uint256) {
        FactoryMerkle.CustomFeeUSD memory customFee = _customFeesUSD[campaignCreator];
        return customFee.enabled ? customFee.fee : minFeeUSD;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
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
