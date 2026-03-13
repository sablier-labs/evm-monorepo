// SPDX-License-Identifier: GPL-3.0-or-later
// BobVaultShare.spec — Certora CVL specification for BobVaultShare
//
// Covers:
//   Inv 18: totalSupply == sum of all balances
//   Inv 19: Only SablierBob can change totalSupply (mint/burn)

methods {
    // BobVaultShare getters
    function totalSupply()                     external returns (uint256) envfree;
    function balanceOf(address)                external returns (uint256) envfree;
    function SABLIER_BOB()                     external returns (address) envfree;
    function VAULT_ID()                        external returns (uint256) envfree;
    function allowance(address, address)       external returns (uint256) envfree;

    // State-changing functions
    function mint(uint256, address, uint256)   external;
    function burn(uint256, address, uint256)   external;
    function transfer(address, uint256)        external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256)         external returns (bool);

    // External call from BobVaultShare._update() to SablierBob.onShareTransfer()
    // Summarized as NONDET because it does NOT modify BobVaultShare state —
    // it only updates adapter wstETH attribution in the SablierBob contract.
    function _.onShareTransfer(uint256, address, address, uint256, uint256) external => NONDET;
}

/*//////////////////////////////////////////////////////////////////////////
                            GHOSTS & HOOKS
//////////////////////////////////////////////////////////////////////////*/

// Ghost variable tracking the sum of all balances
ghost mathint sumOfBalances {
    init_state axiom sumOfBalances == 0;
}

// Hook on balance storage updates — OZ ERC20 stores balances in mapping _balances
hook Sstore _balances[KEY address account] uint256 newBalance (uint256 oldBalance) {
    sumOfBalances = sumOfBalances + newBalance - oldBalance;
}

/*//////////////////////////////////////////////////////////////////////////
                    INV 18: totalSupply == sum of balances
//////////////////////////////////////////////////////////////////////////*/

/// @title Invariant: totalSupply equals the sum of all individual balances
/// @notice This is a fundamental ERC-20 accounting invariant (Pattern 1: ghost sum).
///         The per-function preserved blocks are needed because OZ ERC20 v5 uses `unchecked`
///         arithmetic in _update() (line 205: `_balances[to] += value`). The prover's induction
///         step can otherwise pick adversarial states where a balance is near max_uint256 and
///         the unchecked addition wraps. The requires are safe: when the invariant holds, all
///         balances are non-negative uint256 summing to totalSupply, so no two can exceed it
///         and totalSupply + mint amount must fit in uint256 (enforced by OZ's checked add).
invariant totalSupplyIsSumOfBalances()
    to_mathint(totalSupply()) == sumOfBalances
    {
        preserved transfer(address to, uint256 amount) with (env e) {
            requireInvariant totalSupplyIsSumOfBalances();
            require to_mathint(balanceOf(e.msg.sender)) + to_mathint(balanceOf(to))
                <= to_mathint(totalSupply()),
                "safe: any two balances sum to at most totalSupply when invariant holds";
        }
        preserved transferFrom(address from, address to, uint256 amount) with (env e) {
            requireInvariant totalSupplyIsSumOfBalances();
            require to_mathint(balanceOf(from)) + to_mathint(balanceOf(to))
                <= to_mathint(totalSupply()),
                "safe: any two balances sum to at most totalSupply when invariant holds";
        }
        preserved mint(uint256 vaultId, address to, uint256 amount) with (env e) {
            requireInvariant totalSupplyIsSumOfBalances();
            require to_mathint(totalSupply()) + to_mathint(amount) <= max_uint256,
                "safe: OZ _update uses checked add for _totalSupply on mint";
            require to_mathint(balanceOf(to)) + to_mathint(amount) <= max_uint256,
                "safe: balanceOf(to) <= totalSupply (invariant) and totalSupply + amount <= max_uint256";
        }
        preserved burn(uint256 vaultId, address from, uint256 amount) with (env e) {
            requireInvariant totalSupplyIsSumOfBalances();
            require to_mathint(balanceOf(from)) <= to_mathint(totalSupply()),
                "safe: any individual balance <= totalSupply when invariant holds (sum of non-negative parts)";
        }
    }

/*//////////////////////////////////////////////////////////////////////////
                INV 19: Only SablierBob can mint/burn (change supply)
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: totalSupply only changes when caller is SABLIER_BOB
/// @notice Parametric rule — for any function f, if totalSupply changes, msg.sender must be SABLIER_BOB
rule onlySablierBobCanChangeTotalSupply(method f) filtered {
    f -> !f.isView && f.selector != sig:approve(address,uint256).selector
} {
    uint256 supplyBefore = totalSupply();
    address sablierBob = SABLIER_BOB();

    env e;
    calldataarg args;
    f(e, args);

    uint256 supplyAfter = totalSupply();

    assert supplyAfter != supplyBefore => e.msg.sender == sablierBob,
        "Inv 19: totalSupply changed by non-SablierBob caller";
}

/*//////////////////////////////////////////////////////////////////////////
                        ADDITIONAL SHARE TOKEN PROPERTIES
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: transfer preserves totalSupply
/// @notice Transferring tokens between accounts should not change totalSupply
rule transferPreservesTotalSupply(address to, uint256 amount) {
    uint256 supplyBefore = totalSupply();

    env e;
    transfer(e, to, amount);

    uint256 supplyAfter = totalSupply();

    assert supplyAfter == supplyBefore,
        "transfer must not change totalSupply";
}

/// @title Rule: transferFrom preserves totalSupply
rule transferFromPreservesTotalSupply(address from, address to, uint256 amount) {
    uint256 supplyBefore = totalSupply();

    env e;
    transferFrom(e, from, to, amount);

    uint256 supplyAfter = totalSupply();

    assert supplyAfter == supplyBefore,
        "transferFrom must not change totalSupply";
}
