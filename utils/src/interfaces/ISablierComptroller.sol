// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IRoleAdminable } from "./IRoleAdminable.sol";

/// @title ISablierComptroller
/// @notice Manage fees across all Sablier protocols. State-changing functions are only accessible to the admin and the
/// fee manager.
interface ISablierComptroller is IRoleAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       TYPES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct encapsulating the minimum fee for the Merkle campaigns and the custom fees for each creator.
    /// @param minFeeUSD The minimum fee in USD, denominated in Chainlink's 8-decimal format for USD prices, where 1e8
    /// is $1.
    /// @param customFees A mapping of custom fees mapped by campaign creator addresses.
    struct AirdropsFees {
        uint256 minFeeUSD;
        mapping(address campaignCreator => CustomFeeUSD) customFeesUSD;
    }

    /// @notice Struct encapsulating the parameters of a custom USD fee.
    /// @param enabled Whether the fee is enabled. If false, the min USD fee will apply instead.
    /// @param fee The fee amount.
    struct CustomFeeUSD {
        bool enabled;
        uint256 fee;
    }

    /// @notice Struct encapsulating the minimum fee for the {SablierFlow} contract and the custom fees for each sender.
    /// @param minFeeUSD The minimum fee in USD, denominated in Chainlink's 8-decimal format for USD prices, where 1e8
    /// is $1.
    /// @param customFees A mapping of custom fees mapped by senders.
    struct FlowFees {
        uint256 minFeeUSD;
        mapping(address sender => CustomFeeUSD) customFeesUSD;
    }

    /// @notice Struct encapsulating the minimum fee for the {SablierLockup} contract and the custom fees for each
    /// sender.
    /// @param minFeeUSD The minimum fee in USD, denominated in Chainlink's 8-decimal format for USD prices, where 1e8
    /// is $1.
    /// @param customFees A mapping of custom fees mapped by senders.
    struct LockupFees {
        uint256 minFeeUSD;
        mapping(address sender => CustomFeeUSD) customFeesUSD;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin or the fee collector collects the accrued fees.
    event CollectFees(address indexed feeRecipient, uint256 feeAmount);

    /// @notice Emitted when the admin or the fee manager resets the airdrops custom USD fee for the provided campaign
    /// creator to the minimum fee.
    event DisableAirdropsCustomFeeUSD(address indexed campaignCreator);

    /// @notice Emitted when the admin or the fee manager resets the flow custom USD fee for the provided sender to the
    /// minimum fee.
    event DisableFlowCustomFeeUSD(address indexed sender);

    /// @notice Emitted when the admin or the fee manager resets the lockup custom USD fee for the provided sender to
    /// the minimum fee.
    event DisableLockupCustomFeeUSD(address indexed sender);

    /// @notice Emitted when a target contract is called.
    event Execute(address indexed target, bytes data, bytes result);

    /// @notice Emitted when the admin or the fee manager sets an airdrops custom USD fee for the provided campaign
    /// creator.
    event SetAirdropsCustomFeeUSD(address indexed campaignCreator, uint256 customFeeUSD);

    /// @notice Emitted when the airdrops min USD fee is set by the admin or the fee manager.
    event SetAirdropsMinFeeUSD(uint256 newMinFeeUSD, uint256 previousMinFeeUSD);

    /// @notice Emitted when the admin or the fee manager sets a flow custom USD fee for the provided sender.
    event SetFlowCustomFeeUSD(address indexed sender, uint256 customFeeUSD);

    /// @notice Emitted when the flow min USD fee is set by the admin or the fee manager.
    event SetFlowMinFeeUSD(uint256 newMinFeeUSD, uint256 previousMinFeeUSD);

    /// @notice Emitted when the admin or the fee manager sets a lockup custom USD fee for the provided sender.
    event SetLockupCustomFeeUSD(address indexed sender, uint256 customFeeUSD);

    /// @notice Emitted when the lockup min USD fee is set by the admin or the fee manager.
    event SetLockupMinFeeUSD(uint256 newMinFeeUSD, uint256 previousMinFeeUSD);

    /// @notice Emitted when the oracle contract address is set by the admin.
    event SetOracle(address indexed admin, address newOracle, address previousOracle);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the maximum USD fee that can be set for claiming an airdrop or withdrawing from a stream.
    /// @dev This is a constant state variable and is 100e8, which is equivalent to $100.
    function MAX_FEE_USD() external view returns (uint256);

    /// @notice Calculates the minimum fee in wei to claim from an airdrop.
    /// @dev Refer to `calculateMinFeeWei(uint256 minFeeUSD)` for more details on how the fee is calculated.
    function calculateAirdropsMinFeeWei() external view returns (uint256);

    /// @notice Calculates the minimum fee in wei applicable for the provided campaign creator.
    /// @dev Refer to `calculateMinFeeWei(uint256 minFeeUSD)` for more details on how the fee is calculated.
    function calculateAirdropsMinFeeWeiFor(address campaignCreator) external view returns (uint256);

    /// @notice Calculates the minimum fee in wei required to withdraw from a flow stream.
    /// @dev Refer to `calculateMinFeeWei(uint256 minFeeUSD)` for more details on how the fee is calculated.
    function calculateFlowMinFeeWei() external view returns (uint256);

    /// @notice Calculates the minimum fee in wei applicable for the provided sender.
    /// @dev Refer to `calculateMinFeeWei(uint256 minFeeUSD)` for more details on how the fee is calculated.
    function calculateFlowMinFeeWeiFor(address sender) external view returns (uint256);

    /// @notice Calculates the minimum fee in wei required to withdraw from a lockup stream.
    /// @dev Refer to `calculateMinFeeWei(uint256 minFeeUSD)` for more details on how the fee is calculated.
    function calculateLockupMinFeeWei() external view returns (uint256);

    /// @notice Calculates the minimum fee in wei applicable for the provided sender.
    /// @dev Refer to `calculateMinFeeWei(uint256 minFeeUSD)` for more details on how the fee is calculated.
    function calculateLockupMinFeeWeiFor(address sender) external view returns (uint256);

    /// @notice Calculates the minimum fee in wei required to either claim an airdrop or to withdraw from a stream.
    /// @dev The price is considered to be 0 if:
    /// 1. The oracle is not set.
    /// 2. The min USD fee is 0.
    /// 3. The oracle price is ≤ 0.
    /// 4. The oracle's update timestamp is in the future.
    /// 5. The oracle price hasn't been updated in the last 24 hours.
    ///
    /// @param minFeeUSD The min USD fee, denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    /// @return The minimum fee in wei, denominated in 18 decimals (1e18 = 1 native token).
    function calculateMinFeeWei(uint256 minFeeUSD) external view returns (uint256);

    /// @notice Retrieves the min USD fee required to claim an airdrop, paid in the native token of the chain, e.g.,
    /// ETH for Ethereum Mainnet.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function getAirdropsMinFeeUSD() external view returns (uint256);

    /// @notice Determines the min USD fee applicable for the provided campaign creator. By default, the min USD fee is
    /// applied unless there is a custom USD fee set.
    /// @param campaignCreator The address of the campaign creator.
    /// @return The min USD fee, denominated in Chainlink's 8-decimal format for USD prices.
    function getAirdropsMinFeeUSDFor(address campaignCreator) external view returns (uint256);

    /// @notice Retrieves the min USD fee required to withdraw from a flow stream, paid in the native token of the
    /// chain, e.g., ETH for Ethereum Mainnet.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function getFlowMinFeeUSD() external view returns (uint256);

    /// @notice Determines the min USD fee applicable for the provided sender. By default, the min USD fee is
    /// applied unless there is a custom USD fee set.
    /// @param sender The address of the sender.
    /// @return The min USD fee, denominated in Chainlink's 8-decimal format for USD prices.
    function getFlowMinFeeUSDFor(address sender) external view returns (uint256);

    /// @notice Retrieves the min USD fee required to withdraw from a lockup stream, paid in the native token of the
    /// chain, e.g., ETH for Ethereum Mainnet.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function getLockupMinFeeUSD() external view returns (uint256);

    /// @notice Determines the min USD fee applicable for the provided sender. By default, the min USD fee is
    /// applied unless there is a custom USD fee set.
    /// @param sender The address of the sender.
    /// @return The min USD fee, denominated in Chainlink's 8-decimal format for USD prices.
    function getLockupMinFeeUSDFor(address sender) external view returns (uint256);

    /// @notice Retrieves the oracle contract address, which provides price data for the native token.
    /// @dev A zero address indicates that the oracle is not set.
    function oracle() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Collects fees from this contract. If `feeRecipient` is a contract, it must be able to receive native
    /// tokens, e.g., ETH for Ethereum Mainnet.
    ///
    /// @dev Emits a {CollectFees} event.
    ///
    /// Requirements:
    /// - If `msg.sender` has neither the {IRoleAdminable.FEE_COLLECTOR_ROLE} role nor is the contract admin, then
    /// `feeRecipient` must be the admin address.
    ///
    /// @param feeRecipient The address where the fees will be collected.
    function collectFees(address feeRecipient) external;

    /// @notice Disables the custom USD fee for the provided campaign creator, who will now pay the min USD fee.
    /// @dev Emits a {DisableAirdropsCustomFeeUSD} event.
    ///
    /// Notes:
    /// - The minimum fee will apply only to future campaigns. Fees for past campaigns remain unchanged.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    ///
    /// @param campaignCreator The user to disable the custom fee for.
    function disableAirdropsCustomFeeUSD(address campaignCreator) external;

    /// @notice Disables the custom USD fee for the provided sender, whose streams will now pay the min USD fee.
    /// @dev Emits a {DisableFlowCustomFeeUSD} event.
    ///
    /// Notes:
    /// - The minimum fee will apply to all streams that are created by the sender.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    ///
    /// @param sender The user to disable the custom fee for.
    function disableFlowCustomFeeUSD(address sender) external;

    /// @notice Disables the custom USD fee for the provided sender, whose streams will now pay the min USD fee.
    /// @dev Emits a {DisableLockupCustomFeeUSD} event.
    ///
    /// Notes:
    /// - The minimum fee will apply to all streams that are created by the sender.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    ///
    /// @param sender The user to disable the custom fee for.
    function disableLockupCustomFeeUSD(address sender) external;

    /// @notice Executes an external call to any contract and function.
    ///
    /// @dev Emits an {Execute} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - `target` must be a contract.
    ///
    /// @param target The address of the target contract on which the data is executed.
    /// @param data Function selector plus ABI encoded data.
    /// @return result The result from the call.
    function execute(address target, bytes calldata data) external returns (bytes memory result);

    /// @notice Sets a custom USD fee for the provided campaign creator.
    /// @dev Emits a {SetAirdropsCustomFeeUSD} event.
    ///
    /// Notes:
    /// - The custom USD fee will apply only to future campaigns. Fees for past campaigns remain unchanged.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `customFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param campaignCreator The user for whom the fee is set.
    /// @param customFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setAirdropsCustomFeeUSD(address campaignCreator, uint256 customFeeUSD) external;

    /// @notice Sets the min USD fee for upcoming campaigns.
    /// @dev Emits a {SetAirdropsMinFeeUSD} event.
    ///
    /// Notes:
    /// - The new USD fee will apply only to future campaigns. Fees for past campaigns remain unchanged.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `newMinFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param newMinFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setAirdropsMinFeeUSD(uint256 newMinFeeUSD) external;

    /// @notice Sets a custom USD fee for the provided sender.
    /// @dev Emits a {SetFlowCustomFeeUSD} event.
    ///
    /// Notes:
    /// - The custom USD fee will apply to all streams that are created by the sender.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `customFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param sender The user for whom the fee is set.
    /// @param customFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setFlowCustomFeeUSD(address sender, uint256 customFeeUSD) external;

    /// @notice Sets the min USD fee for {SablierFlow} streams.
    /// @dev Emits a {SetFlowMinFeeUSD} event.
    ///
    /// Notes:
    /// - The new USD fee will apply to all streams.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `newMinFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param newMinFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setFlowMinFeeUSD(uint256 newMinFeeUSD) external;

    /// @notice Sets a custom USD fee for the provided sender.
    /// @dev Emits a {SetLockupCustomFeeUSD} event.
    ///
    /// Notes:
    /// - The custom USD fee will apply to all streams that are created by the sender.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `customFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param sender The user for whom the fee is set.
    /// @param customFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setLockupCustomFeeUSD(address sender, uint256 customFeeUSD) external;

    /// @notice Sets the min USD fee for {SablierLockup} streams.
    /// @dev Emits a {SetLockupMinFeeUSD} event.
    ///
    /// Notes:
    /// - The new USD fee will apply to all streams.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `newMinFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param newMinFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setLockupMinFeeUSD(uint256 newMinFeeUSD) external;

    /// @notice Sets the oracle contract address. The zero address can be used to disable the oracle.
    /// @dev Emits a {SetOracle} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - If `newOracle` is not the zero address, the call to it must not fail.
    ///
    /// @param newOracle The new oracle contract address. It can be the zero address.
    function setOracle(address newOracle) external;

    /// @notice Transfers fees from the Lockup and Flow protocols, and then collects fees from this contract.
    /// @dev Emits a {CollectFees} event.
    ///
    /// Notes:
    /// - If `feeRecipient` is a contract, it must be able to receive native tokens, e.g., ETH for Ethereum Mainnet.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_COLLECTOR_ROLE} role.
    ///
    /// @param flow The address of the {SablierFlow} contract.
    /// @param lockup The address of the {SablierLockup} contract.
    /// @param feeRecipient The address to which the fees will be sent.
    function transferAndCollectFees(address flow, address lockup, address feeRecipient) external;
}
