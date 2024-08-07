// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Broker } from "./../types/DataTypes.sol";
import { Errors } from "./Errors.sol";

/// @title Helpers
/// @notice Library with helper functions in {SablierFlow} contract.
library Helpers {
    using SafeCast for uint256;

    /// @notice Calculates the normalized amount using the asset's decimals.
    /// @dev Changes the transfer amount based on the asset's decimal difference from 18:
    /// - if the asset has 18 decimals, the transfer amount is returned.
    /// - if the asset has fewer decimals, the amount is increased.
    function calculateNormalizedAmount(
        uint128 transferAmount,
        uint8 assetDecimals
    )
        internal
        pure
        returns (uint128 normalizedAmount)
    {
        // Return the transfer amount if asset's decimals is 18.
        if (assetDecimals == 18) {
            return transferAmount;
        }

        uint8 normalizingFactor;

        // Safe to use unchecked because the subtraction cannot overflow.
        unchecked {
            normalizingFactor = 18 - assetDecimals;
        }

        normalizedAmount = (transferAmount * (10 ** normalizingFactor)).toUint128();
    }

    /// @notice Calculates the transfer amount based on the asset's decimals.
    /// @dev Changes the amount based on the asset's decimal difference from 18:
    /// - if the asset has 18 decimals, the amount is returned.
    /// - if the asset has fewer decimals, the amount is reduced.
    function calculateTransferAmount(
        uint128 amount,
        uint8 assetDecimals
    )
        internal
        pure
        returns (uint128 transferAmount)
    {
        // Return the original amount if asset's decimals is 18.
        if (assetDecimals == 18) {
            return amount;
        }

        uint8 normalizingFactor;

        // Safe to use unchecked because the subtraction and division cannot overflow.
        unchecked {
            normalizingFactor = 18 - assetDecimals;
            transferAmount = (amount / (10 ** normalizingFactor)).toUint128();
        }
    }

    /// @dev Checks the `Broker` parameter, and then calculates the broker fee amount and the transfer amount from the
    /// total transfer amount.
    function checkAndCalculateBrokerFee(
        uint128 totalTransferAmount,
        Broker memory broker,
        UD60x18 maxBrokerFee
    )
        internal
        pure
        returns (uint128, uint128)
    {
        // Check: the broker's fee is not greater than `MAX_BROKER_FEE`.
        if (broker.fee.gt(maxBrokerFee)) {
            revert Errors.SablierFlow_BrokerFeeTooHigh(broker.fee, maxBrokerFee);
        }

        // Check: the broker recipient is not the zero address.
        if (broker.account == address(0)) {
            revert Errors.SablierFlow_BrokerAddressZero();
        }

        // Calculate the broker fee amount that is going to be transfer to the `broker.account`.
        // The cast to uint128 is safe because the maximum fee is hard coded.
        uint128 brokerFeeAmount = ud(totalTransferAmount).mul(broker.fee).intoUint256().toUint128();

        // Calculate the transfer amount to the Flow contract.
        uint128 transferAmount = totalTransferAmount - brokerFeeAmount;

        return (brokerFeeAmount, transferAmount);
    }

    /// @notice Retrieves the asset's decimals safely, reverts with a custom error if an error occurs.
    /// @dev Performs a low-level call to handle assets decimals that are implemented as a number less than 256.
    function safeAssetDecimals(address asset) internal view returns (uint8) {
        (bool success, bytes memory returnData) = asset.staticcall(abi.encodeCall(IERC20Metadata.decimals, ()));
        if (success && returnData.length == 32) {
            return abi.decode(returnData, (uint8));
        } else {
            revert Errors.SablierFlow_InvalidAssetDecimals(asset);
        }
    }
}
