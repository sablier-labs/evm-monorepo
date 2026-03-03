// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC1822Proxiable } from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IRoleAdminable } from "./IRoleAdminable.sol";

/// @title ISablierComptroller
/// @notice Manage fees across all Sablier protocols. State-changing functions are only accessible to the admin and the
/// fee manager.
interface ISablierComptroller is IERC165, IERC1822Proxiable, IRoleAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       TYPES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct encapsulating the parameters of a custom USD fee.
    /// @param enabled Whether the fee is enabled. If false, the min USD fee will apply instead.
    /// @param fee The fee amount in USD, denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    struct CustomFeeUSD {
        bool enabled;
        uint256 fee;
    }

    /// @notice Enum representing the different protocols supported by the comptroller.
    enum Protocol {
        Airdrops,
        Flow,
        Lockup,
        Staking,
        Bob
    }

    /// @notice Struct encapsulating the fees for a protocol.
    /// @param minFeeUSD The minimum fee in USD, denominated in Chainlink's 8-decimal format for USD prices, where 1e8
    /// is $1.
    /// @param customFees Custom fees struct mapped by user address.
    struct ProtocolFees {
        uint256 minFeeUSD;
        mapping(address user => CustomFeeUSD) customFeesUSD;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a target contract is called.
    event Execute(address indexed target, bytes targetCallData, bytes result);

    /// @notice Emitted when the attestor is set.
    event SetAttestor(address indexed caller, address indexed previousAttestor, address indexed newAttestor);

    /// @notice Emitted when the admin or the fee manager sets a new minimum USD fee.
    event SetMinFeeUSD(Protocol indexed protocol, address caller, uint256 previousMinFeeUSD, uint256 newMinFeeUSD);

    /// @notice Emitted when the oracle contract address is set by the admin.
    event SetOracle(address indexed admin, address previousOracle, address newOracle);

    /// @notice Emitted when the admin or the fee collector transfers the accrued fees to the fee recipient.
    event TransferFees(address indexed feeRecipient, uint256 feeAmount);

    /// @notice Emitted when the admin or the fee manager sets/disables the custom USD fee for the provided user.
    event UpdateCustomFeeUSD(
        Protocol indexed protocol,
        address caller,
        address indexed user,
        uint256 previousMinFeeUSD,
        uint256 newMinFeeUSD
    );

    /// @notice Emitted when the admin withdraws ERC-20 tokens from the comptroller.
    event WithdrawERC20Token(address indexed admin, IERC20 indexed token, address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the maximum USD fee that can be set for claiming an airdrop or withdrawing from a stream.
    /// @dev This is a constant state variable and is 100e8, which is equivalent to $100.
    function MAX_FEE_USD() external view returns (uint256);

    /// @notice The minimal interface ID of the comptroller.
    /// @dev Any new comptroller must support the minimal interface ID made up of the following functions:
    /// 1. {calculateMinFeeWeiFor} - used by protocols inherited from {IComptrollerable}.
    /// 2. {convertUSDFeeToWei}    - used by protocols inherited from {IComptrollerable}.
    /// 3. {execute}               - used by comptroller admin to perform necessary operations.
    /// 4. {getMinFeeUSDFor}       - used by protocols inherited from {IComptrollerable}.
    function MINIMAL_INTERFACE_ID() external view returns (bytes4);

    /// @notice The version of the comptroller contract.
    /// @dev This follows the format "v{Major}.{Minor}" (e.g., "v1.1").
    function VERSION() external view returns (string memory);

    /// @notice Retrieves the attestor address used for verifying attestation signatures in merkle campaigns.
    /// @dev A zero address indicates that the attestor is not set.
    function attestor() external view returns (address);

    /// @notice Calculates the minimum fee in wei for the given protocol.
    /// @dev See the documentation for {convertUSDFeeToWei} for more details.
    /// @param protocol The protocol as defined in {Protocol} enum.
    function calculateMinFeeWei(Protocol protocol) external view returns (uint256);

    /// @notice Calculates the minimum fee in wei for the provided user for the given protocol.
    /// @dev If the custom fee is enabled, it returns the custom fee, otherwise it returns the default minimum fee. See
    /// the documentation for {convertUSDFeeToWei} for more details.
    /// @param protocol The protocol as defined in {Protocol} enum.
    /// @param user The user address.
    function calculateMinFeeWeiFor(Protocol protocol, address user) external view returns (uint256);

    /// @notice Converts the fee amount from USD to Wei.
    /// @dev The price is considered to be 0 if:
    /// 1. The oracle is not set.
    /// 2. The min USD fee is 0.
    /// 3. The oracle price is ≤ 0.
    /// 4. The oracle's update timestamp is in the future.
    /// 5. The oracle price hasn't been updated in the last 24 hours.
    ///
    /// @param feeUSD The fee in USD, denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    /// @return The fee in wei, denominated in 18 decimals (1e18 = 1 native token).
    function convertUSDFeeToWei(uint256 feeUSD) external view returns (uint256);

    /// @notice Get the minimum fee in USD for the given protocol, paid in the native token of the chain, e.g.,
    /// ETH for Ethereum Mainnet. Use {calculateMinFeeWei} to retrieve the fee in wei.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function getMinFeeUSD(Protocol protocol) external view returns (uint256);

    /// @notice Get the minimum fee in USD for the provided user for the given protocol, paid in the native token of the
    /// chain, e.g., ETH for Ethereum Mainnet. Use {calculateMinFeeWeiFor} to retrieve the fee in wei.
    /// @dev The fee is denominated in Chainlink's 8-decimal format for USD prices, where 1e8 is $1.
    function getMinFeeUSDFor(Protocol protocol, address user) external view returns (uint256);

    /// @notice Retrieves the oracle contract address, which provides price data for the native token.
    /// @dev A zero address indicates that the oracle is not set.
    function oracle() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Disables the custom USD fee for the provided user for the given protocol, defaulting to the minimum fee.
    /// @dev Emits an {UpdateCustomFeeUSD} event.
    ///
    /// Notes:
    /// - In case of airdrops, the new fee applies only to the future campaigns created by the user. Past campaigns are
    /// not affected.
    /// - In case of streams, the new fee applies immediately to all the streams created by user.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    ///
    /// @param protocol The protocol as defined in {Protocol} enum.
    /// @param user The user address.
    function disableCustomFeeUSDFor(Protocol protocol, address user) external;

    /// @notice Executes an external call to any contract and function.
    ///
    /// @dev Emits an {Execute} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - `target` must be a contract.
    ///
    /// @param target The address of the target contract on which the data is executed.
    /// @param targetCallData Function selector plus ABI encoded data.
    /// @return result The result from the call.
    function execute(address target, bytes calldata targetCallData) external returns (bytes memory result);

    /// @notice Calls `lowerMinFeeUSD` function on an existing campaign.
    ///
    /// @dev Notes:
    /// - This function is a pass-through to the campaign's {ISablierMerkleBase.lowerMinFeeUSD} function.
    /// - All validations are expected to be performed in the campaign's `lowerMinFeeUSD` function.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    ///
    /// @param campaign The address of an existing campaign.
    /// @param newMinFeeUSD The new min USD fee to set, denominated in 8 decimals.
    function lowerMinFeeUSDForCampaign(address campaign, uint256 newMinFeeUSD) external;

    /// @notice Sets the attestor address used for verifying attestation signatures in airdrop campaigns.
    ///
    /// @dev Emits a {SetAttestor} event.
    ///
    /// Notes:
    /// - The default attestor to be used in merkle campaigns. It can be overridden by setting a different attestor in
    /// the campaign contract.
    /// - Setting it to zero address would disable attestation-based claims globally.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.ATTESTOR_MANAGER_ROLE} role.
    ///
    /// @param newAttestor The new attestor address. It can be the zero address.
    function setAttestor(address newAttestor) external;

    /// @notice Calls `setAttestor` function on an existing campaign contract.
    ///
    /// @dev Notes:
    /// - This function is a pass-through to the campaign's `setAttestor` function.
    /// - All validations are expected to be performed in the campaign's `setAttestor` function.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.ATTESTOR_MANAGER_ROLE} role.
    /// - Setting it to zero address would allow merkle campaigns to use the default attestor.
    ///
    /// @param campaign The address of an existing campaign contract.
    /// @param newAttestor The new attestor address.
    function setAttestorForCampaign(address campaign, address newAttestor) external;

    /// @notice Sets the custom USD fee for the provided user for the given protocol.
    /// @dev Emits an {UpdateCustomFeeUSD} event.
    ///
    /// Notes:
    /// - In case of airdrops, the new fee applies only to the future campaigns created by the user. Past campaigns are
    /// not affected.
    /// - In case of streams, the new fee applies immediately to all the streams created by user.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `customFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param protocol The protocol as defined in {Protocol} enum.
    /// @param user The user address.
    /// @param customFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setCustomFeeUSDFor(Protocol protocol, address user, uint256 customFeeUSD) external;

    /// @notice Sets a new min USD fee for the given protocol.
    /// @dev Emits a {SetMinFeeUSD} event.
    ///
    /// Notes:
    /// - In case of airdrops, the new fee applies only to the future campaigns created by the user. Past campaigns are
    /// not affected.
    /// - In case of streams, the new fee applies immediately to all the streams created by user.
    ///
    /// Requirements:
    /// - `msg.sender` must be either the admin or have the {IRoleAdminable.FEE_MANAGEMENT_ROLE} role.
    /// - `newMinFeeUSD` must be less than or equal to {MAX_FEE_USD}.
    ///
    /// @param protocol The protocol as defined in {Protocol} enum.
    /// @param newMinFeeUSD The custom USD fee to set, denominated in 8 decimals.
    function setMinFeeUSD(Protocol protocol, uint256 newMinFeeUSD) external;

    /// @notice Sets the oracle contract address. The zero address can be used to disable the oracle.
    /// @dev Emits a {SetOracle} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - If `newOracle` is not the zero address, the call to it must not fail.
    ///
    /// @param newOracle The new oracle contract address. It can be the zero address.
    function setOracle(address newOracle) external;

    /// @notice Transfers fees from the given protocol addresses to this contract, and then transfer the entire balance
    /// of this contract to the fee recipient.
    /// @dev Emits a {TransferFees} event.
    ///
    /// Notes:
    /// - If `feeRecipient` is a contract, it must be able to receive native tokens, e.g., ETH for Ethereum Mainnet.
    /// - `protocolAddresses` can be empty.
    ///
    /// Requirements:
    /// `feeRecipient` must not be the zero address.
    /// - If `msg.sender` has neither the {IRoleAdminable.FEE_COLLECTOR_ROLE} role nor is the contract admin, then
    /// `feeRecipient` must be the admin address.
    /// - `protocolAddresses` must implement the {IComptrollerable} interface.
    ///
    /// @param protocolAddresses An array of addresses of the Sablier protocols from which fees is transferred from.
    /// @param feeRecipient The address to which the entire fee from this contract is transferred.
    function transferFees(address[] calldata protocolAddresses, address feeRecipient) external;

    /// @notice Withdraws the entire ERC-20 token balance from the comptroller to a specified recipient.
    /// @dev Emits a {WithdrawERC20Token} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    /// - `to` must not be the zero address.
    /// - The token balance of this contract must not be zero.
    ///
    /// @param token The ERC-20 token to withdraw.
    /// @param to The address to send the tokens to.
    function withdrawERC20Token(IERC20 token, address to) external;
}
