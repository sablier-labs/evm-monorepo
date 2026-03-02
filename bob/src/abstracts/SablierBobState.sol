// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBobVaultShare } from "../interfaces/IBobVaultShare.sol";
import { ISablierBobAdapter } from "../interfaces/ISablierBobAdapter.sol";
import { ISablierBobState } from "../interfaces/ISablierBobState.sol";
import { Errors } from "../libraries/Errors.sol";
import { Bob } from "../types/Bob.sol";

/// @title SablierBobState
/// @notice See the documentation in {ISablierBobState}.
abstract contract SablierBobState is ISablierBobState {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Default adapters mapped by token address.
    mapping(IERC20 token => ISablierBobAdapter adapter) internal _defaultAdapters;

    /// @inheritdoc ISablierBobState
    address public override nativeToken;

    /// @inheritdoc ISablierBobState
    uint256 public override nextVaultId;

    /// @dev Vaults mapped by unsigned integers.
    mapping(uint256 vaultId => Bob.Vault vault) internal _vaults;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `vaultId` does not reference a null vault.
    modifier notNull(uint256 vaultId) {
        _notNull(vaultId);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initializes the state variables.
    constructor() {
        // Set the next vault ID to 1.
        nextVaultId = 1;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBobState
    function getAdapter(uint256 vaultId) external view override notNull(vaultId) returns (ISablierBobAdapter adapter) {
        adapter = _vaults[vaultId].adapter;
    }

    /// @inheritdoc ISablierBobState
    function getDefaultAdapterFor(IERC20 token) external view override returns (ISablierBobAdapter adapter) {
        adapter = _defaultAdapters[token];
    }

    /// @inheritdoc ISablierBobState
    function getExpiry(uint256 vaultId) external view override notNull(vaultId) returns (uint40 expiry) {
        expiry = _vaults[vaultId].expiry;
    }

    /// @inheritdoc ISablierBobState
    function getLastSyncedAt(uint256 vaultId) external view override notNull(vaultId) returns (uint40 lastSyncedAt) {
        lastSyncedAt = _vaults[vaultId].lastSyncedAt;
    }

    /// @inheritdoc ISablierBobState
    function getLastSyncedPrice(uint256 vaultId)
        external
        view
        override
        notNull(vaultId)
        returns (uint128 lastSyncedPrice)
    {
        lastSyncedPrice = _vaults[vaultId].lastSyncedPrice;
    }

    /// @inheritdoc ISablierBobState
    function getOracle(uint256 vaultId) external view override notNull(vaultId) returns (AggregatorV3Interface oracle) {
        oracle = _vaults[vaultId].oracle;
    }

    /// @inheritdoc ISablierBobState
    function getShareToken(uint256 vaultId)
        external
        view
        override
        notNull(vaultId)
        returns (IBobVaultShare shareToken)
    {
        shareToken = _vaults[vaultId].shareToken;
    }

    /// @inheritdoc ISablierBobState
    function getTargetPrice(uint256 vaultId) external view override notNull(vaultId) returns (uint128 targetPrice) {
        targetPrice = _vaults[vaultId].targetPrice;
    }

    /// @inheritdoc ISablierBobState
    function getUnderlyingToken(uint256 vaultId) external view override notNull(vaultId) returns (IERC20 token) {
        token = _vaults[vaultId].token;
    }

    /// @inheritdoc ISablierBobState
    function isStakedInAdapter(uint256 vaultId) external view override notNull(vaultId) returns (bool stakedInAdapter) {
        stakedInAdapter = _vaults[vaultId].isStakedInAdapter;
    }

    /// @inheritdoc ISablierBobState
    function statusOf(uint256 vaultId) external view override notNull(vaultId) returns (Bob.Status status) {
        status = _statusOf(vaultId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Retrieves the vault's status without performing a null check.
    function _statusOf(uint256 vaultId) internal view returns (Bob.Status) {
        Bob.Vault memory vault = _vaults[vaultId];

        // Return EXPIRED if the vault has expired.
        if (block.timestamp >= vault.expiry) {
            return Bob.Status.EXPIRED;
        }

        // Return SETTLED if the last synced price is greater than or equal to the target price.
        if (vault.lastSyncedPrice >= vault.targetPrice) {
            return Bob.Status.SETTLED;
        }

        // Otherwise, return ACTIVE.
        return Bob.Status.ACTIVE;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if `vaultId` references a null vault.
    /// @dev A private function is used instead of inlining this logic in a modifier because Solidity copies modifiers
    /// into every function that uses them.
    function _notNull(uint256 vaultId) private view {
        // A vault is considered null if its token address is zero, as tokens are always checked on creation.
        if (address(_vaults[vaultId].token) == address(0)) {
            revert Errors.SablierBobState_Null(vaultId);
        }
    }
}
