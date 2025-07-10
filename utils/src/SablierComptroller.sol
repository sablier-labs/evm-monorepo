// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IComptrollerable } from "./interfaces/IComptrollerable.sol";
import { ISablierComptroller } from "./interfaces/ISablierComptroller.sol";
import { Errors } from "./libraries/Errors.sol";
import { RoleAdminable } from "./RoleAdminable.sol";

/// @title SablierComptroller
/// @notice See the documentation in {ISablierComptroller}.
contract SablierComptroller is ISablierComptroller, RoleAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierComptroller
    uint256 public constant override MAX_FEE_USD = 100e8;

    /// @inheritdoc ISablierComptroller
    address public override oracle;

    /// @dev A mapping of protocol fees.
    mapping(Protocol protocol => ProtocolFees fees) private _protocolFees;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if `newFeeUSD` exceeds the maximum allowed fee.
    modifier notExceedMaxFeeUSD(uint256 newFeeUSD) {
        _notExceedMaxFeeUSD(newFeeUSD);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial contract admin.
    /// @param initialAirdropMinFeeUSD The initial airdrops min USD fee charged.
    /// @param initialFlowMinFeeUSD The initial flow min USD fee charged.
    /// @param initialLockupMinFeeUSD The initial lockup min USD fee charged.
    /// @param initialOracle The initial oracle contract address.
    constructor(
        address initialAdmin,
        uint256 initialAirdropMinFeeUSD,
        uint256 initialFlowMinFeeUSD,
        uint256 initialLockupMinFeeUSD,
        address initialOracle
    )
        RoleAdminable(initialAdmin)
    {
        _protocolFees[Protocol.Airdrops].minFeeUSD = initialAirdropMinFeeUSD;
        _protocolFees[Protocol.Flow].minFeeUSD = initialFlowMinFeeUSD;
        _protocolFees[Protocol.Lockup].minFeeUSD = initialLockupMinFeeUSD;

        if (initialOracle != address(0)) {
            _setOracle(initialOracle);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Receive function to accept native tokens.
    receive() external payable { }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierComptroller
    function calculateMinFeeWei(Protocol protocol) external view override returns (uint256) {
        // Get the minimum fee in USD.
        uint256 minFeeUSD = _protocolFees[protocol].minFeeUSD;

        // Convert the minimum fee from USD to wei.
        return _convertUSDFeeToWei(minFeeUSD);
    }

    /// @inheritdoc ISablierComptroller
    function calculateMinFeeWeiFor(Protocol protocol, address user) external view override returns (uint256) {
        // Get the minimum fee in USD.
        uint256 minFeeUSD = _getMinFeeUSDFor(protocol, user);

        // Convert the minimum fee from USD to wei.
        return _convertUSDFeeToWei(minFeeUSD);
    }

    /// @inheritdoc ISablierComptroller
    function convertUSDFeeToWei(uint256 feeUSD) external view override returns (uint256) {
        return _convertUSDFeeToWei(feeUSD);
    }

    /// @inheritdoc ISablierComptroller
    function getMinFeeUSD(Protocol protocol) external view override returns (uint256) {
        return _protocolFees[protocol].minFeeUSD;
    }

    /// @inheritdoc ISablierComptroller
    function getMinFeeUSDFor(Protocol protocol, address user) external view override returns (uint256) {
        return _getMinFeeUSDFor(protocol, user);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierComptroller
    function disableCustomFeeUSDFor(Protocol protocol, address user) external override onlyRole(FEE_MANAGEMENT_ROLE) {
        // Effect: delete the custom fee for the provided protocol and user.
        delete _protocolFees[protocol].customFeesUSD[user];

        // Log the update.
        emit ISablierComptroller.DisableCustomFeeUSD(protocol, user);
    }

    /// @inheritdoc ISablierComptroller
    function execute(address target, bytes calldata data) external override onlyAdmin returns (bytes memory result) {
        bool success;

        // Interactions: call the target contract with the provided data.
        (success, result) = target.call(data);

        // Check whether the call was successful or not.
        if (!success) {
            // If there is result, bubble it up and revert.
            if (result.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // Get the length of the result stored in the first 32 bytes.
                    let resultSize := mload(result)

                    // Forward the pointer by 32 bytes to skip the length argument, and revert with the result.
                    revert(add(result, 32), resultSize)
                }
            }
            // Otherwise, revert with custom error.
            else {
                revert Errors.SablierComptroller_ExecutionFailedSilently();
            }
        }

        // Log the execution.
        emit ISablierComptroller.Execute(target, data, result);
    }

    /// @inheritdoc ISablierComptroller
    function setCustomFeeUSDFor(
        Protocol protocol,
        address user,
        uint256 customFeeUSD
    )
        external
        override
        onlyRole(FEE_MANAGEMENT_ROLE)
        notExceedMaxFeeUSD(customFeeUSD)
    {
        // Effect: enable the custom fee, if it is not already enabled.
        if (!_protocolFees[protocol].customFeesUSD[user].enabled) {
            _protocolFees[protocol].customFeesUSD[user].enabled = true;
        }

        // Effect: update the custom fee for the provided protocol and user.
        _protocolFees[protocol].customFeesUSD[user].fee = customFeeUSD;

        // Log the update.
        emit ISablierComptroller.SetCustomFeeUSD(protocol, user, customFeeUSD);
    }

    /// @inheritdoc ISablierComptroller
    function setMinFeeUSD(
        Protocol protocol,
        uint256 newMinFeeUSD
    )
        external
        override
        onlyRole(FEE_MANAGEMENT_ROLE)
        notExceedMaxFeeUSD(newMinFeeUSD)
    {
        // Load what the previous fee will be.
        uint256 previousMinFeeUSD = _protocolFees[protocol].minFeeUSD;

        // Effect: update the minimum USD fee for the provided protocol.
        _protocolFees[protocol].minFeeUSD = newMinFeeUSD;

        // Log the update.
        emit ISablierComptroller.SetMinFeeUSD(protocol, previousMinFeeUSD, newMinFeeUSD);
    }

    /// @inheritdoc ISablierComptroller
    function setOracle(address newOracle) external override onlyAdmin {
        address currentOracle = oracle;

        // Effects: set the new oracle.
        _setOracle(newOracle);

        // Log the update.
        emit ISablierComptroller.SetOracle({ admin: msg.sender, previousOracle: currentOracle, newOracle: newOracle });
    }

    /// @inheritdoc ISablierComptroller
    function transferFees(address[] calldata protocolAddresses, address feeRecipient) external override {
        // Check: if `msg.sender` has neither the {RoleAdminable.FEE_COLLECTOR_ROLE} role nor is the contract admin,
        // `feeRecipient` must be the admin address.
        bool hasRoleOrIsAdmin = _hasRoleOrIsAdmin({ role: FEE_COLLECTOR_ROLE, account: msg.sender });
        if (!hasRoleOrIsAdmin && feeRecipient != admin) {
            revert Errors.SablierComptroller_FeeRecipientNotAdmin({ feeRecipient: feeRecipient, admin: admin });
        }

        // Interactions: transfer the fees from the provided protocol addresses to this contract.
        for (uint256 i = 0; i < protocolAddresses.length; ++i) {
            IComptrollerable(protocolAddresses[i]).transferFeesToComptroller();
        }

        // Get this contract's balance.
        uint256 feeAmount = address(this).balance;

        // Interaction: transfer the fees to the fee recipient.
        (bool success,) = feeRecipient.call{ value: feeAmount }("");

        // Revert if the call failed.
        if (!success) {
            revert Errors.SablierComptroller_FeeTransferFailed(feeRecipient, feeAmount);
        }

        // Log the fee withdrawal.
        emit TransferFees(feeRecipient, feeAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _convertUSDFeeToWei(uint256 minFeeUSD) private view returns (uint256) {
        // If the oracle is not set, return 0.
        if (oracle == address(0)) {
            return 0;
        }

        // If the min USD fee is 0, skip the calculations.
        if (minFeeUSD == 0) {
            return 0;
        }

        // Interactions: query the oracle price and the time at which it was updated.
        (, int256 price,, uint256 updatedAt,) = AggregatorV3Interface(oracle).latestRoundData();

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
        uint8 oracleDecimals = AggregatorV3Interface(oracle).decimals();

        // Adjust the price so that it has 8 decimals.
        uint256 price8D;
        if (oracleDecimals == 8) {
            price8D = uint256(price);
        } else if (oracleDecimals < 8) {
            // The price is assumed to be much less than the maximum value of `uint256` so it is safe to multiply.
            price8D = uint256(price) * 10 ** (8 - oracleDecimals);
        } else {
            price8D = uint256(price) / 10 ** (oracleDecimals - 8);
        }

        // Multiply by 10^18 because the native token is assumed to have 18 decimals.
        return minFeeUSD * 1e18 / price8D;
    }

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _getMinFeeUSDFor(Protocol protocol, address user) private view returns (uint256) {
        // Get the custom fee for the user.
        ISablierComptroller.CustomFeeUSD memory customFee = _protocolFees[protocol].customFeesUSD[user];

        uint256 minFeeUSD;

        // If the custom fee is enabled, use it, otherwise use the minimum fee.
        if (customFee.enabled) {
            minFeeUSD = customFee.fee;
        } else {
            minFeeUSD = _protocolFees[protocol].minFeeUSD;
        }

        // Return the minimum fee in USD.
        return minFeeUSD;
    }

    /// @dev A private function is used instead of inlining this logic in a modifier because Solidity copies modifiers
    /// into every function that uses them.
    function _notExceedMaxFeeUSD(uint256 newFeeUSD) private pure {
        // Check: the new fee is not greater than the maximum allowed.
        if (newFeeUSD > MAX_FEE_USD) {
            revert Errors.SablierComptroller_MaxFeeUSDExceeded(newFeeUSD, MAX_FEE_USD);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev See the documentation for the user-facing functions that call this private function.
    function _setOracle(address newOracle) private {
        // Check: oracle implements the `latestRoundData` function.
        if (newOracle != address(0)) {
            AggregatorV3Interface(newOracle).latestRoundData();
        }

        // Effect: update the oracle.
        oracle = newOracle;
    }
}
