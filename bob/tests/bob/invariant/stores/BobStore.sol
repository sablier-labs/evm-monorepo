// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";

/// @notice Storage contract that tracks vault state for invariant assertions.
contract BobStore {
    /*//////////////////////////////////////////////////////////////////////////
                                       TYPES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Metadata for a created vault.
    struct VaultMeta {
        bool hasAdapter;
        IERC20 token;
        IBobVaultShare shareToken;
    }

    /// @dev Data captured from each successful `enter` or `enterWithNativeToken` call.
    struct EnterData {
        address user;
        uint256 vaultId;
        uint128 amount;
        uint256 shareBalanceBefore;
        uint256 shareBalanceAfter;
        uint256 tokenBalanceBobBefore;
        uint256 tokenBalanceBobAfter;
        bool usedNativeToken;
        uint256 msgValue;
    }

    /// @dev Data captured from each successful `redeem` call.
    struct RedeemData {
        address user;
        uint256 vaultId;
        uint128 shareBalanceBefore;
        uint256 shareBalanceAfter;
        uint128 transferAmount;
        uint128 feeAmountDeductedFromYield;
        uint256 tokenBalanceUserBefore;
        uint256 tokenBalanceUserAfter;
        bool hasAdapter;
        uint128 userWstETHBeforeRedeem;
    }

    /// @dev Data captured right after `createVault` to verify creation-time properties.
    struct CreationData {
        uint256 vaultId;
        bool hasAdapter;
        bool isStakedInAdapter;
        address shareToken;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Array of all created vault IDs.
    uint256[] public vaultIds;

    /// @dev Array of non-adapter vault IDs.
    uint256[] public nonAdapterVaultIds;

    /// @dev Array of adapter vault IDs.
    uint256[] public adapterVaultIds;

    /// @dev Maps vault ID to its metadata.
    mapping(uint256 vaultId => VaultMeta) internal _vaultMeta;

    /// @dev Maps vault ID to its list of depositors.
    mapping(uint256 vaultId => address[]) internal _vaultDepositors;

    /// @dev Dedup guard for depositor array.
    mapping(uint256 vaultId => mapping(address user => bool)) internal _isDepositor;

    /// @dev Records from each enter call.
    EnterData[] internal _enterRecords;

    /// @dev Records from each redeem call.
    RedeemData[] internal _redeemRecords;

    /// @dev Records from each vault creation.
    CreationData[] internal _creationRecords;

    /// @dev Cumulative amount deposited per vault (for Inv 8 conservation).
    mapping(uint256 vaultId => uint256) public totalDeposited;

    /// @dev Cumulative shares burned per vault (for Inv 8 conservation).
    mapping(uint256 vaultId => uint256) public totalSharesBurned;

    /// @dev WETH received after unstaking per adapter vault (for Inv 24).
    mapping(uint256 vaultId => uint128) public unstakeResults;

    /// @dev Cumulative WETH distributed (transferAmount + fee) per adapter vault (for Inv 24).
    mapping(uint256 vaultId => uint256) public totalRedemptionDistributed;

    /// @dev Snapshot of total wstETH at unstake time per vault (for Inv 27).
    mapping(uint256 vaultId => uint128) public snapshotTotalWstETH;

    /// @dev Snapshot of user wstETH at unstake time (for Inv 27).
    mapping(uint256 vaultId => mapping(address user => uint128)) public snapshotUserWstETH;

    /// @dev Guard to prevent double-snapshot (redeem auto-unstakes).
    mapping(uint256 vaultId => bool) public wstETHSnapshotTaken;

    /// @dev Per-user per-vault redeem lookup (for Inv 27).
    mapping(uint256 vaultId => mapping(address user => RedeemData)) internal _userRedeemForVault;

    /// @dev Whether Lido withdrawal has been requested for a vault.
    mapping(uint256 vaultId => bool) public lidoWithdrawalRequested;

    /*//////////////////////////////////////////////////////////////////////////
                                     FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // --- Vault ID management ---

    function vaultCount() external view returns (uint256) {
        return vaultIds.length;
    }

    function nonAdapterVaultCount() external view returns (uint256) {
        return nonAdapterVaultIds.length;
    }

    function adapterVaultCount() external view returns (uint256) {
        return adapterVaultIds.length;
    }

    function pushVaultId(uint256 vaultId, bool hasAdapter) external {
        vaultIds.push(vaultId);
        if (hasAdapter) {
            adapterVaultIds.push(vaultId);
        } else {
            nonAdapterVaultIds.push(vaultId);
        }
    }

    // --- Vault metadata ---

    function getVaultMeta(uint256 vaultId) external view returns (VaultMeta memory) {
        return _vaultMeta[vaultId];
    }

    function setVaultMeta(uint256 vaultId, VaultMeta calldata meta) external {
        _vaultMeta[vaultId] = meta;
    }

    // --- Depositor tracking ---

    function addDepositor(uint256 vaultId, address user) external {
        if (!_isDepositor[vaultId][user]) {
            _isDepositor[vaultId][user] = true;
            _vaultDepositors[vaultId].push(user);
        }
    }

    function getVaultDepositors(uint256 vaultId) external view returns (address[] memory) {
        return _vaultDepositors[vaultId];
    }

    function vaultDepositorCount(uint256 vaultId) external view returns (uint256) {
        return _vaultDepositors[vaultId].length;
    }

    // --- Enter records ---

    function enterRecordCount() external view returns (uint256) {
        return _enterRecords.length;
    }

    function getEnterRecord(uint256 index) external view returns (EnterData memory) {
        return _enterRecords[index];
    }

    function pushEnterRecord(EnterData calldata data) external {
        _enterRecords.push(data);
    }

    // --- Redeem records ---

    function redeemRecordCount() external view returns (uint256) {
        return _redeemRecords.length;
    }

    function getRedeemRecord(uint256 index) external view returns (RedeemData memory) {
        return _redeemRecords[index];
    }

    function pushRedeemRecord(RedeemData calldata data) external {
        _redeemRecords.push(data);
        _userRedeemForVault[data.vaultId][data.user] = data;
    }

    function getUserRedeemForVault(uint256 vaultId, address user) external view returns (RedeemData memory) {
        return _userRedeemForVault[vaultId][user];
    }

    // --- Creation records ---

    function creationRecordCount() external view returns (uint256) {
        return _creationRecords.length;
    }

    function getCreationRecord(uint256 index) external view returns (CreationData memory) {
        return _creationRecords[index];
    }

    function pushCreationRecord(CreationData calldata data) external {
        _creationRecords.push(data);
    }

    // --- Aggregate tracking ---

    function addTotalDeposited(uint256 vaultId, uint256 amount) external {
        totalDeposited[vaultId] += amount;
    }

    function addTotalSharesBurned(uint256 vaultId, uint256 amount) external {
        totalSharesBurned[vaultId] += amount;
    }

    function setUnstakeResults(uint256 vaultId, uint128 wethReceived) external {
        unstakeResults[vaultId] = wethReceived;
    }

    function addTotalRedemptionDistributed(uint256 vaultId, uint256 amount) external {
        totalRedemptionDistributed[vaultId] += amount;
    }

    function setSnapshotTotalWstETH(uint256 vaultId, uint128 amount) external {
        snapshotTotalWstETH[vaultId] = amount;
    }

    function setSnapshotUserWstETH(uint256 vaultId, address user, uint128 amount) external {
        snapshotUserWstETH[vaultId][user] = amount;
    }

    function setWstETHSnapshotTaken(uint256 vaultId) external {
        wstETHSnapshotTaken[vaultId] = true;
    }

    function setLidoWithdrawalRequested(uint256 vaultId) external {
        lidoWithdrawalRequested[vaultId] = true;
    }
}
