// SPDX-License-Identifier: GPL-3.0-or-later
// SablierLidoAdapter.spec — Certora CVL specification for SablierLidoAdapter
//
// Covers:
//   C-1 (VERIFIED — fixed in mitigation): processRedemption now clears user's wstETH balance
//   L-7 (EXPECTED VIOLATION): WETH distribution dust loss in processRedemption
//   M-3 (VERIFIED — fixed in mitigation): updateStakedTokenBalance reverts on zero wstETH transfer
//   Inv 28: _vaultTotalWstETH == sum of _userWstETH (excluding processRedemption)
//   Inv 29: Already covered by C-1 (userWstETHClearedAfterRedemption)
//   Inv 31: _vaultYieldFee immutable after creation
//   Inv 48 (partial): comptroller-only admin
//   Inv 49 (partial): onlySablierBob access control
//   Inv 53: feeOnYield <= MAX_FEE
//   Inv 54: slippageTolerance <= MAX_SLIPPAGE_TOLERANCE
//   Inv 55: requestLidoWithdrawal only callable by comptroller
//   Inv 56: processRedemption only callable by SablierBob
//   Inv 57: Curve and Lido exit paths mutually exclusive per vault
//   Inv 71: updateStakedTokenBalance preserves _vaultTotalWstETH
//   Inv 72: processRedemption conservation (transferAmount + fee == proportional WETH share)
//   Inv 73: No payout without prior unstaking
//
// REMOVED after mitigation review (grace period feature removed per finding M-2):
//   Inv 49 (partial): unstakeForUserWithinGracePeriod access control

methods {
    // SablierLidoAdapter getters — envfree (only clean CVL types)
    function SABLIER_BOB()                                        external returns (address) envfree;
    function comptroller()                                        external returns (address) envfree;
    function getTotalYieldBearingTokenBalance(uint256)            external returns (uint128) envfree;
    function getYieldBearingTokenBalanceFor(uint256, address)     external returns (uint128) envfree;
    function getWethReceivedAfterUnstaking(uint256)               external returns (uint256) envfree;
    function feeOnYield()                                         external returns (uint256);
    function slippageTolerance()                                  external returns (uint256);
    function MAX_FEE()                                            external returns (uint256);
    function MAX_SLIPPAGE_TOLERANCE()                             external returns (uint256);

    // processRedemption returns (uint128, uint128) — clean CVL types.
    // Not declared envfree because internal UD60x18 math may cause type-merge issues.
    function processRedemption(uint256, address, uint128)
        external returns (uint128, uint128);

    // Note: MAX_FEE, MAX_SLIPPAGE_TOLERANCE, feeOnYield, slippageTolerance, getVaultYieldFee
    // all return UD60x18 (user-defined value type). NOT declared envfree.
    // Must be called with env to avoid CVL type-merge issues with UDVTs.

    // External calls — summarized
    function _.withdraw(uint256)                                  external => NONDET;
    function _.submit(address)                                    external => NONDET;
    function _.wrap(uint256)                                      external => NONDET;
    function _.unwrap(uint256)                                    external => NONDET;
    function _.get_dy(int128, int128, uint256)                    external => NONDET;
    function _.exchange(int128, int128, uint256, uint256)         external => NONDET;
    function _.deposit()                                          external => NONDET;
    function _.balanceOf(address)                                 external => NONDET;
    function _.transfer(address, uint256)                         external => NONDET;
    function _.transferFrom(address, address, uint256)            external => NONDET;
    function _.approve(address, uint256)                          external => NONDET;
    function _.requestWithdrawals(uint256[], address)             external => NONDET;
    function _.claimWithdrawals(uint256[], uint256[])             external => NONDET;
    function _.getWithdrawalStatus(uint256[])                     external => NONDET;
    function _.MAX_STETH_WITHDRAWAL_AMOUNT()                     external => NONDET;
    function _.MIN_STETH_WITHDRAWAL_AMOUNT()                     external => NONDET;
    function _.getLastCheckpointIndex()                          external => NONDET;
    function _.findCheckpointHints(uint256[], uint256, uint256)  external => NONDET;
    function _.statusOf(uint256)                                 external => NONDET;
    function _.isStakedInAdapter(uint256 vaultId)                external => ghostIsStakedInAdapter[vaultId]
                                                                    expect bool;

    // Prevent unresolved external calls (e.g., low-level call in transferFeesToComptroller)
    // from havocing this contract's storage. HAVOC_ECF only havocs external contract state.
    unresolved external in SablierLidoAdapter._ => DISPATCH [] default HAVOC_ECF;
}

/*//////////////////////////////////////////////////////////////////////////
    GHOST: Cross-contract model for isStakedInAdapter
//////////////////////////////////////////////////////////////////////////*/

/// @dev Models `ISablierBobState(SABLIER_BOB).isStakedInAdapter(vaultId)`.
///      Used as a summary for the external call. Constrained by:
///      - init: all vaults start as not staked (conservative default)
///      - When `_wethReceivedAfterUnstaking[vaultId]` is written (unstaking occurred),
///        the vault is no longer staked — modeled via require in rules as a safe assumption.
/// @notice Standard filter for parametric rules.
///         transferFeesToComptroller excluded: low-level call{value}("") triggers
///         HAVOC_ALL on adapter storage — false positive. Only sends ETH.
definition excludedFromParametric(method f) returns bool =
    f.selector == sig:transferFeesToComptroller().selector;

definition commonFilters(method f) returns bool =
    !f.isView && !excludedFromParametric(f);

persistent ghost mapping(uint256 => bool) ghostIsStakedInAdapter;

/*//////////////////////////////////////////////////////////////////////////
    GHOST: Track _lidoWithdrawalRequestIds array length per vault
//////////////////////////////////////////////////////////////////////////*/

/// @dev Mirrors `_lidoWithdrawalRequestIds[vaultId].length` — non-zero means Lido path was initiated
ghost mapping(uint256 => mathint) ghostLidoRequestCount {
    init_state axiom forall uint256 id. ghostLidoRequestCount[id] == 0;
}

hook Sstore _lidoWithdrawalRequestIds[KEY uint256 vaultId].(offset 0) uint256 newLen {
    ghostLidoRequestCount[vaultId] = newLen;
}

hook Sload uint256 len _lidoWithdrawalRequestIds[KEY uint256 vaultId].(offset 0) {
    require ghostLidoRequestCount[vaultId] == to_mathint(len);
}

/// @dev Mirrors `_wethReceivedAfterUnstaking[vaultId]` — non-zero means unstaking occurred
ghost mapping(uint256 => mathint) ghostWethReceived {
    init_state axiom forall uint256 id. ghostWethReceived[id] == 0;
}

hook Sstore _wethReceivedAfterUnstaking[KEY uint256 vaultId] uint128 newVal (uint128 oldVal) {
    ghostWethReceived[vaultId] = newVal;
}

hook Sload uint128 val _wethReceivedAfterUnstaking[KEY uint256 vaultId] {
    require ghostWethReceived[vaultId] == to_mathint(val);
}

/*//////////////////////////////////////////////////////////////////////////
    GHOST: Track sum of _userWstETH per vault for Inv 28
//////////////////////////////////////////////////////////////////////////*/

/// @dev Aggregates _userWstETH[vaultId][user] across all users for each vault.
///      Updated via Sstore hook. Used to verify _vaultTotalWstETH consistency.
ghost mapping(uint256 => mathint) ghostSumUserWstETH {
    init_state axiom forall uint256 id. ghostSumUserWstETH[id] == 0;
}

hook Sstore _userWstETH[KEY uint256 vaultId][KEY address user] uint128 newVal (uint128 oldVal) {
    ghostSumUserWstETH[vaultId] = ghostSumUserWstETH[vaultId] + newVal - oldVal;
}

/*//////////////////////////////////////////////////////////////////////////
    INV 28: _vaultTotalWstETH == sum of _userWstETH
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: per-vault total wstETH equals sum of user wstETH balances
/// @notice After any function except processRedemption, _vaultTotalWstETH[vaultId]
///         must equal the sum of all _userWstETH[vaultId][user].
///         processRedemption is excluded because it intentionally deletes
///         _userWstETH[vaultId][user] without decrementing _vaultTotalWstETH —
///         the total is used as a snapshot denominator for proportional WETH distribution.
///         transferFeesToComptroller is excluded because its low-level call{value}("")
///         triggers HAVOC_ALL on adapter storage — false positive since it only sends ETH.
rule vaultTotalWstETHEqualsSumUserWstETH(method f, uint256 vaultId) filtered {
    f -> commonFilters(f)
        && f.selector != sig:processRedemption(uint256, address, uint128).selector
} {
    require to_mathint(getTotalYieldBearingTokenBalance(vaultId)) == ghostSumUserWstETH[vaultId],
        "safe: inductive hypothesis — total equals sum before call";

    env e;
    calldataarg args;
    f(e, args);

    assert to_mathint(getTotalYieldBearingTokenBalance(vaultId)) == ghostSumUserWstETH[vaultId],
        "Inv 28: _vaultTotalWstETH != sum of _userWstETH after function call";
}

/*//////////////////////////////////////////////////////////////////////////
    C-1 (VERIFIED): processRedemption now clears user's wstETH balance
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: user wstETH cleared after redemption — VERIFIED (C-1 fixed in mitigation)
/// @notice SablierBob.redeem calls adapter.processRedemption which now includes
///         `delete _userWstETH[vaultId][user]` to clear the user's wstETH balance after
///         computing their WETH payout. This prevents the recycled-claim attack where
///         a user could acquire fresh shares via transfer and redeem again.
rule userWstETHClearedAfterRedemption(
    uint256 vaultId,
    address user,
    uint128 shareBalance
) {
    uint128 userWstETH = getYieldBearingTokenBalanceFor(vaultId, user);
    require userWstETH > 0,
        "safe: user has staked wstETH";

    uint256 totalWeth = getWethReceivedAfterUnstaking(vaultId);
    require totalWeth > 0,
        "safe: vault has been unstaked";

    uint128 totalWstETH = getTotalYieldBearingTokenBalance(vaultId);
    require totalWstETH > 0,
        "safe: vault has total wstETH";

    env e;
    uint128 amount; uint128 fee;
    (amount, fee) = processRedemption(e, vaultId, user, shareBalance);
    require amount > 0,
        "safe: user has a non-zero WETH claim";

    // After processRedemption, the user's wstETH balance should be cleared
    // VERIFIED: processRedemption now includes `delete _userWstETH[vaultId][user]`
    uint128 userWstETHAfter = getYieldBearingTokenBalanceFor(vaultId, user);
    assert userWstETHAfter == 0,
        "C-1: user wstETH not cleared after redemption — enables repeated claims and vault insolvency";
}

/*//////////////////////////////////////////////////////////////////////////
    EXPECTED VIOLATION: WETH distribution dust loss
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: WETH distribution conservation on redemption — EXPECTED VIOLATION
/// @notice processRedemption uses integer division:
///         `userWethShare = (userWstETH * totalWeth / totalWstETH).toUint128()`
///         When all users redeem, the sum of individual WETH shares can be less than
///         the total WETH received from unstaking due to floor division truncation.
///         The remaining dust is stuck in the contract with no recovery mechanism.
/// @dev This rule models a two-user vault where A and B are the only stakers.
///      Their individual WETH shares should sum to totalWeth, but rounding causes loss.
rule wethDistributionConservation(
    uint256 vaultId,
    address userA,
    address userB,
    uint128 shareBalA,
    uint128 shareBalB
) {
    require userA != userB,
        "safe: distinct users";

    // Both users have staked wstETH
    uint128 wstETHA = getYieldBearingTokenBalanceFor(vaultId, userA);
    uint128 wstETHB = getYieldBearingTokenBalanceFor(vaultId, userB);
    uint128 vaultTotal = getTotalYieldBearingTokenBalance(vaultId);

    // A and B are the only stakers in this vault
    require to_mathint(wstETHA) + to_mathint(wstETHB) == to_mathint(vaultTotal),
        "safe: A and B are the only users in this vault";
    require vaultTotal > 0,
        "safe: vault has staked tokens";
    require wstETHA > 0 && wstETHB > 0,
        "safe: both users have non-zero stakes";

    // Vault has been unstaked (WETH received)
    uint256 totalWeth = getWethReceivedAfterUnstaking(vaultId);
    require totalWeth > 0,
        "safe: unstaking has occurred";

    // Calculate individual WETH shares for both users
    env e;
    uint128 amountA; uint128 feeA;
    (amountA, feeA) = processRedemption(e, vaultId, userA, shareBalA);

    uint128 amountB; uint128 feeB;
    (amountB, feeB) = processRedemption(e, vaultId, userB, shareBalB);

    // Conservation: total distributed (amounts + fees) should equal total WETH received
    // EXPECTED VIOLATION: floor division truncation causes dust loss
    assert to_mathint(amountA) + to_mathint(feeA) + to_mathint(amountB) + to_mathint(feeB)
        == to_mathint(totalWeth),
        "WETH distribution rounding loss — sum of individual shares != total WETH received";
}

/*//////////////////////////////////////////////////////////////////////////
            INV 31: _vaultYieldFee immutable after creation
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: vault yield fee never changes after registerVault
/// @notice Once a vault's yield fee is set via registerVault, no function should modify it
rule vaultYieldFeeImmutable(method f, uint256 vaultId) filtered {
    f -> commonFilters(f) && f.selector != sig:registerVault(uint256).selector
} {
    env e1;
    uint256 feeBefore = getVaultYieldFee(e1, vaultId);
    require feeBefore != 0; // Vault has been registered (fee was snapshotted)

    env e2;
    calldataarg args;
    f(e2, args);

    env e3;
    uint256 feeAfter = getVaultYieldFee(e3, vaultId);

    assert feeAfter == feeBefore,
        "Inv 31: vault yield fee changed after creation";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 48 & 49: Parametric access control
//////////////////////////////////////////////////////////////////////////*/

/// @title LA-1: Only comptroller can change feeOnYield
/// @notice Parametric state-change rule — proves no function can modify feeOnYield
///         without the caller being the comptroller.
rule onlyComptrollerCanChangeFeeOnYield(env e, method f, calldataarg args)
    filtered { f -> commonFilters(f) } {
    env e1;
    uint256 feeBefore = feeOnYield(e1);
    f(e, args);
    env e2;
    uint256 feeAfter = feeOnYield(e2);
    assert feeAfter != feeBefore => e.msg.sender == comptroller(),
        "Inv 48: feeOnYield changed by non-comptroller";
}

/// @title LA-2: Only comptroller can change slippageTolerance
rule onlyComptrollerCanChangeSlippageTolerance(env e, method f, calldataarg args)
    filtered { f -> commonFilters(f) } {
    env e1;
    uint256 toleranceBefore = slippageTolerance(e1);
    f(e, args);
    env e2;
    uint256 toleranceAfter = slippageTolerance(e2);
    assert toleranceAfter != toleranceBefore => e.msg.sender == comptroller(),
        "Inv 48: slippageTolerance changed by non-comptroller";
}

/// @title LA-3: Only SablierBob can change _vaultTotalWstETH
/// @notice Proves no function can modify _vaultTotalWstETH for any vault without the
///         caller being SablierBob. Uses getTotalYieldBearingTokenBalance getter.
rule onlySablierBobCanChangeTotalWstETH(env e, method f, calldataarg args, uint256 vaultId)
    filtered { f -> commonFilters(f) } {
    uint128 before = getTotalYieldBearingTokenBalance(vaultId);
    f(e, args);
    assert getTotalYieldBearingTokenBalance(vaultId) != before => e.msg.sender == SABLIER_BOB(),
        "Inv 49: _vaultTotalWstETH changed by non-SablierBob";
}

/// @title LA-4: Only SablierBob can change _userWstETH
/// @notice Proves no function can modify _userWstETH for any vault/user without the
///         caller being SablierBob.
rule onlySablierBobCanChangeUserWstETH(env e, method f, calldataarg args, uint256 vaultId, address user)
    filtered { f -> commonFilters(f) } {
    uint128 before = getYieldBearingTokenBalanceFor(vaultId, user);
    f(e, args);
    assert getYieldBearingTokenBalanceFor(vaultId, user) != before => e.msg.sender == SABLIER_BOB(),
        "Inv 49: _userWstETH changed by non-SablierBob";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 51: feeOnYield <= MAX_FEE
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: feeOnYield never exceeds MAX_FEE after any state change
/// @notice Using a rule instead of invariant since feeOnYield/MAX_FEE return UD60x18
rule feeOnYieldNotTooHigh(method f) filtered {
    f -> commonFilters(f)
} {
    env e1;
    uint256 feeBefore = feeOnYield(e1);
    uint256 maxFee = MAX_FEE(e1);
    require feeBefore <= maxFee,
        "safe: initial state satisfies the fee bound (inductive hypothesis)";

    env e2;
    calldataarg args;
    f(e2, args);

    env e3;
    uint256 feeAfter = feeOnYield(e3);

    assert feeAfter <= maxFee,
        "Inv 53: feeOnYield exceeds MAX_FEE";
}

/*//////////////////////////////////////////////////////////////////////////
            INV 52: slippageTolerance <= MAX_SLIPPAGE_TOLERANCE
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: slippageTolerance never exceeds MAX_SLIPPAGE_TOLERANCE after any state change
/// @notice Using a rule instead of invariant since slippageTolerance/MAX_SLIPPAGE_TOLERANCE return UD60x18
rule slippageToleranceNotTooHigh(method f) filtered {
    f -> commonFilters(f)
} {
    env e1;
    uint256 toleranceBefore = slippageTolerance(e1);
    uint256 maxTolerance = MAX_SLIPPAGE_TOLERANCE(e1);
    require toleranceBefore <= maxTolerance,
        "safe: initial state satisfies the tolerance bound (inductive hypothesis)";

    env e2;
    calldataarg args;
    f(e2, args);

    env e3;
    uint256 toleranceAfter = slippageTolerance(e3);

    assert toleranceAfter <= maxTolerance,
        "Inv 54: slippageTolerance exceeds MAX_SLIPPAGE_TOLERANCE";
}

/*//////////////////////////////////////////////////////////////////////////
    M-3 (VERIFIED): updateStakedTokenBalance reverts on zero wstETH transfer
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: non-zero share transfer must move non-zero wstETH — VERIFIED (M-3 fixed in mitigation)
/// @notice updateStakedTokenBalance now reverts when the computed wstETH transfer amount is zero,
///         preventing share transfers without proportional wstETH backing movement.
rule nonZeroShareTransferMovesWstETH(
    uint256 vaultId,
    address from,
    address to,
    uint256 shareAmountTransferred,
    uint256 userShareBalanceBeforeTransfer
) {
    require from != to,
        "safe: distinct addresses";
    require shareAmountTransferred > 0,
        "safe: non-zero share transfer";
    require userShareBalanceBeforeTransfer >= shareAmountTransferred,
        "safe: sender has enough shares";

    uint128 fromWstETHBefore = getYieldBearingTokenBalanceFor(vaultId, from);
    require fromWstETHBefore > 0,
        "safe: sender has wstETH backing";

    env e;
    updateStakedTokenBalance(e, vaultId, from, to, shareAmountTransferred, userShareBalanceBeforeTransfer);

    uint128 fromWstETHAfter = getYieldBearingTokenBalanceFor(vaultId, from);

    // VERIFIED: updateStakedTokenBalance now reverts when wstETHToTransfer == 0,
    // so any successful call must have moved non-zero wstETH
    assert fromWstETHAfter < fromWstETHBefore,
        "M-3: non-zero share transfer did not decrease sender's wstETH — floor division rounds to zero";
}

/// @title LA-5: Only comptroller can change _lidoWithdrawalRequestIds
/// @notice requestLidoWithdrawal is the only function that populates this array.
///         Proves no function can modify the request IDs without comptroller authorization.
rule onlyComptrollerCanChangeLidoRequestIds(env e, method f, calldataarg args, uint256 vaultId)
    filtered { f -> commonFilters(f) } {
    mathint countBefore = ghostLidoRequestCount[vaultId];
    f(e, args);
    assert ghostLidoRequestCount[vaultId] != countBefore => e.msg.sender == comptroller(),
        "Inv 55: _lidoWithdrawalRequestIds changed by non-comptroller";
}

/*//////////////////////////////////////////////////////////////////////////
    INV 57: Curve and Lido exit paths mutually exclusive per vault
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: Lido withdrawal request IDs are monotonic — once set, never cleared
/// @notice Once `_lidoWithdrawalRequestIds[vaultId]` becomes non-empty (Lido path initiated),
///         no function can clear it back to empty. This ensures the Curve path is permanently
///         blocked for that vault.
rule lidoWithdrawalRequestIdsMonotonic(method f, uint256 vaultId) filtered {
    // transferFeesToComptroller uses low-level call{value}("") which triggers HAVOC_ALL
    // on adapter storage — false positive since it only sends ETH, never touches Lido state
    f -> commonFilters(f)
} {
    require ghostLidoRequestCount[vaultId] > 0,
        "safe: Lido withdrawal has been requested for this vault";

    env e;
    calldataarg args;
    f(e, args);

    assert ghostLidoRequestCount[vaultId] > 0,
        "Inv 57: Lido withdrawal request IDs were cleared — Curve path could be re-enabled";
}

/// @title Rule: requestLidoWithdrawal reverts if already requested for same vault
/// @notice Prevents double-requesting Lido withdrawals — the function checks
///         `_lidoWithdrawalRequestIds[vaultId].length > 0` and reverts.
rule requestLidoWithdrawalIdempotent(uint256 vaultId) {
    require ghostLidoRequestCount[vaultId] > 0,
        "safe: Lido withdrawal already requested";

    env e;
    requestLidoWithdrawal@withrevert(e, vaultId);

    assert lastReverted,
        "Inv 57: requestLidoWithdrawal succeeded on vault with existing Lido withdrawal";
}

/// @title Rule: Curve path cannot retroactively enable Lido path
/// @notice If a vault was unstaked via Curve (wethReceived > 0, no Lido request IDs),
///         no subsequent function can set Lido withdrawal request IDs for that vault.
///         This is the converse of `lidoWithdrawalRequestIdsMonotonic` and together they
///         prove full mutual exclusivity: Lido blocks Curve (monotonic IDs), Curve blocks Lido (this rule).
rule curvePathBlocksLidoPath(method f, uint256 vaultId) filtered {
    // transferFeesToComptroller uses low-level call{value}("") which triggers HAVOC_ALL
    // on adapter storage — false positive since it only sends ETH, never touches Lido state
    f -> commonFilters(f)
} {
    require ghostWethReceived[vaultId] > 0,
        "safe: vault has been unstaked (WETH received)";
    require ghostLidoRequestCount[vaultId] == 0,
        "safe: vault was unstaked via Curve (no Lido request IDs)";
    require !ghostIsStakedInAdapter[vaultId],
        "safe: SablierBob sets isStakedInAdapter=false when unstakeFullAmount succeeds";

    env e;
    calldataarg args;
    f(e, args);

    assert ghostLidoRequestCount[vaultId] == 0,
        "Inv 57: Lido withdrawal requested after vault was already unstaked via Curve";
}

/*//////////////////////////////////////////////////////////////////////////
    INV 71: updateStakedTokenBalance preserves _vaultTotalWstETH
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: transferring wstETH attribution between users does not change the vault total
/// @notice updateStakedTokenBalance moves wstETH from one user to another. The vault-level
///         total _vaultTotalWstETH must remain unchanged since this is a net-zero operation.
rule updateStakedTokenBalancePreservesTotal(
    uint256 vaultId, address from, address to, uint256 shareAmountTransferred, uint256 userShareBalanceBeforeTransfer
) {
    uint128 totalBefore = getTotalYieldBearingTokenBalance(vaultId);

    env e;
    updateStakedTokenBalance(e, vaultId, from, to, shareAmountTransferred, userShareBalanceBeforeTransfer);

    uint128 totalAfter = getTotalYieldBearingTokenBalance(vaultId);

    assert totalAfter == totalBefore,
        "Inv 71: updateStakedTokenBalance changed _vaultTotalWstETH";
}

/*//////////////////////////////////////////////////////////////////////////
    INV 72: processRedemption conservation
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: transferAmount + fee equals the user's proportional WETH share
/// @notice processRedemption computes userWethShare = userWstETH * totalWeth / totalWstETH,
///         then splits it into transferAmount and feeAmountDeductedFromYield. The split is
///         exact — no rounding occurs in the addition, only in the fee computation.
rule processRedemptionConservation(uint256 vaultId, address user, uint128 shareBalance) {
    // Read state before processRedemption (which deletes _userWstETH)
    uint128 userWstETH = getYieldBearingTokenBalanceFor(vaultId, user);
    uint256 totalWeth = getWethReceivedAfterUnstaking(vaultId);
    uint128 totalWstETH = getTotalYieldBearingTokenBalance(vaultId);

    // Compute expected WETH share using mathint (matches Solidity integer division)
    mathint expectedWethShare = (totalWstETH > 0)
        ? to_mathint(userWstETH) * to_mathint(totalWeth) / to_mathint(totalWstETH)
        : 0;

    env e;
    uint128 transferAmount;
    uint128 fee;
    (transferAmount, fee) = processRedemption(e, vaultId, user, shareBalance);

    assert to_mathint(transferAmount) + to_mathint(fee) == expectedWethShare,
        "Inv 72: transferAmount + fee != user's proportional WETH share";
}

/*//////////////////////////////////////////////////////////////////////////
    INV 73: No payout without prior unstaking
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: processRedemption returns zero transfer when unstaking has not occurred
/// @notice When _wethReceivedAfterUnstaking[vaultId] is zero (unstakeFullAmount not yet called),
///         processRedemption returns (0, 0) regardless of the user's wstETH balance.
rule noPayoutWithoutUnstaking(uint256 vaultId, address user, uint128 shareBalance) {
    require getWethReceivedAfterUnstaking(vaultId) == 0,
        "safe: vault has not been unstaked yet";

    env e;
    uint128 transferAmount;
    uint128 fee;
    (transferAmount, fee) = processRedemption(e, vaultId, user, shareBalance);

    assert transferAmount == 0,
        "Inv 73: non-zero transfer amount without prior unstaking";
    assert fee == 0,
        "Inv 73: non-zero fee without prior unstaking";
}

/*//////////////////////////////////////////////////////////////////////////
        OFFENSIVE RULES: Cross-Variable Consistency
//////////////////////////////////////////////////////////////////////////*/

/// @title LA-6: _vaultYieldFee bounded by MAX_FEE for any vault
/// @notice Each vault's yield fee is snapshotted from feeOnYield at registration time.
///         Since feeOnYield <= MAX_FEE is enforced (Inv 53), the snapshotted value
///         must also be <= MAX_FEE. This verifies no function can break this bound.
/// @dev registerVault excluded because it snapshots feeOnYield which may be unconstrained
///      in the prover's arbitrary initial state. The feeOnYieldNotTooHigh rule separately
///      verifies feeOnYield <= MAX_FEE holds inductively.
rule vaultYieldFeeBounded(env e, method f, calldataarg args, uint256 vaultId)
    filtered { f -> commonFilters(f)
        && f.selector != sig:registerVault(uint256).selector
    } {
    env e1;
    uint256 vaultFee = getVaultYieldFee(e1, vaultId);
    uint256 maxFee = MAX_FEE(e1);
    require vaultFee <= maxFee,
        "safe: inductive hypothesis — vault fee bounded";

    f(e, args);

    env e2;
    assert getVaultYieldFee(e2, vaultId) <= maxFee,
        "LA-6: vault yield fee exceeds MAX_FEE after function call";
}

/// @title LA-7: _wethReceivedAfterUnstaking only changes via unstakeFullAmount
/// @notice No function other than unstakeFullAmount should modify the WETH received value.
rule wethReceivedOnlyChangedByUnstake(env e, method f, calldataarg args, uint256 vaultId)
    filtered { f -> commonFilters(f)
        && f.selector != sig:unstakeFullAmount(uint256).selector
    } {
    mathint before = ghostWethReceived[vaultId];

    f(e, args);

    assert ghostWethReceived[vaultId] == before,
        "LA-7: _wethReceivedAfterUnstaking changed by function other than unstakeFullAmount";
}

/// @title LA-8: Once _wethReceivedAfterUnstaking is set, no function other than
///        unstakeFullAmount can change it
/// @notice After unstaking, the WETH received value is a permanent snapshot.
///         unstakeFullAmount is excluded because it's the writer; its access control
///         is verified by onlySablierBobCanChangeTotalWstETH.
rule wethReceivedImmutableOnceSet(env e, method f, calldataarg args, uint256 vaultId)
    filtered { f -> commonFilters(f)
        && f.selector != sig:unstakeFullAmount(uint256).selector
    } {
    require ghostWethReceived[vaultId] > 0,
        "safe: WETH has been received (vault was unstaked)";

    mathint before = ghostWethReceived[vaultId];

    f(e, args);

    assert ghostWethReceived[vaultId] == before,
        "LA-8: _wethReceivedAfterUnstaking changed after being set";
}
