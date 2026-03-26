// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { ISablierBob } from "./../../../src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "./../../../src/interfaces/ISablierBobAdapter.sol";
import { SablierAaveAdapter } from "./../../../src/SablierAaveAdapter.sol";
import { Base_Test } from "./../Base.t.sol";

/// @dev Fork tests for the Aave V3 adapter. Uses mainnet state with real Aave pools.
///
/// Yield simulation: Aave's `getReserveNormalizedIncome(asset)` computes the liquidity index on-the-fly using
/// `block.timestamp`. The formula is: `storedIndex * (1 + rate * (now - lastUpdate) / SECONDS_PER_YEAR)`.
/// So `vm.warp()` alone is sufficient to simulate yield accrual — no mocks or storage manipulation needed.
contract AaveAdapter_Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  MAINNET ADDRESSES
    //////////////////////////////////////////////////////////////////////////*/

    address internal constant AAVE_POOL_ADDRESSES_PROVIDER = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    address internal constant COMPTROLLER = 0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399;
    IERC20 internal constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    AggregatorV3Interface internal constant DAI_USD_ORACLE =
        AggregatorV3Interface(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    ISablierBob internal constant FORK_BOB = ISablierBob(0xC8AB7E45E6DF99596b86870c26C25c721eB5C9af);

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST STATE
    //////////////////////////////////////////////////////////////////////////*/

    SablierAaveAdapter internal aaveAdapter;
    address internal depositor;
    address internal depositor2;

    /*//////////////////////////////////////////////////////////////////////////
                                     STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        uint128 depositAmount;
        uint40 vaultDuration;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      SETUP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        vm.createSelectFork({ urlOrAlias: "ethereum" });

        // Deploy the Aave adapter against real Aave V3 contracts.
        aaveAdapter = new SablierAaveAdapter({
            aavePoolAddressesProvider: AAVE_POOL_ADDRESSES_PROVIDER,
            initialComptroller: COMPTROLLER,
            initialYieldFee: ud(0.1e18), // 10%
            sablierBob: address(FORK_BOB)
        });

        // Set the Aave adapter as the default adapter for DAI on the mainnet Bob contract.
        vm.prank(COMPTROLLER);
        FORK_BOB.setDefaultAdapter(DAI, ISablierBobAdapter(address(aaveAdapter)));

        // Create and fund test users.
        depositor = makeAddr("depositor");
        depositor2 = makeAddr("depositor2");
        deal(address(DAI), depositor, 100_000e18);
        deal(address(DAI), depositor2, 100_000e18);

        // Approve Bob to spend DAI.
        vm.prank(depositor);
        DAI.approve(address(FORK_BOB), type(uint256).max);
        vm.prank(depositor2);
        DAI.approve(address(FORK_BOB), type(uint256).max);

        // Label addresses for trace readability.
        vm.label(address(DAI), "DAI");
        vm.label(address(FORK_BOB), "SablierBob");
        vm.label(address(aaveAdapter), "AaveAdapter");
        vm.label(address(aaveAdapter.AAVE_POOL()), "AavePool");
        vm.label(COMPTROLLER, "Comptroller");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates a DAI vault with a target price unreachable for DAI (3x current), so the vault always expires
    /// rather than settles. Returns the vault ID.
    function _createDaiVault(uint40 duration) private returns (uint256 vaultId) {
        (, int256 answer,,,) = DAI_USD_ORACLE.latestRoundData();
        uint128 currentPrice = uint128(uint256(answer));
        uint128 targetPrice = currentPrice * 3; // DAI at $3 won't happen
        uint40 expiry = uint40(block.timestamp) + duration;

        vaultId = FORK_BOB.createVault({ token: DAI, oracle: DAI_USD_ORACLE, expiry: expiry, targetPrice: targetPrice });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Full lifecycle: deposit → yield accrual via vm.warp → redeem. Verifies user receives more than
    /// deposited
    /// and that the yield fee is correctly deducted.
    function testForkFuzz_AaveAdapter_FullLifecycle(Params memory params) public {
        params.depositAmount = uint128(bound(params.depositAmount, 100e18, 50_000e18));
        params.vaultDuration = uint40(bound(params.vaultDuration, 7 days, 30 days));

        uint256 vaultId = _createDaiVault(params.vaultDuration);

        // Enter vault — DAI flows: depositor → adapter → Aave Pool (as aDAI).
        vm.prank(depositor);
        FORK_BOB.enter(vaultId, params.depositAmount);

        // Verify the adapter tracked the deposit as a scaled balance.
        uint128 scaledBalance = aaveAdapter.getYieldBearingTokenBalanceFor(vaultId, depositor);
        assertGt(scaledBalance, 0, "scaled balance should be non-zero");

        // Verify vault value ≈ deposit amount (may differ by 1-2 wei due to ray math rounding).
        uint256 vaultValueBefore = aaveAdapter.getCurrentVaultValue(vaultId);
        assertApproxEqRel(vaultValueBefore, params.depositAmount, 0.001e18, "vault value should match deposit");

        // Warp past expiry. Aave's getReserveNormalizedIncome computes the index using block.timestamp,
        // so the liquidity index will be higher on the next read — no mock or interaction needed.
        uint40 expiry = FORK_BOB.getExpiry(vaultId);
        vm.warp(expiry + 1);

        // Verify yield accrued (vault value grew).
        uint256 vaultValueAfter = aaveAdapter.getCurrentVaultValue(vaultId);
        assertGt(vaultValueAfter, vaultValueBefore, "vault value should increase after warp");

        // Redeem. The first redeem call triggers unstaking (withdraws from Aave) internally.
        uint256 daiBalanceBefore = DAI.balanceOf(depositor);
        uint256 comptrollerBalanceBefore = DAI.balanceOf(COMPTROLLER);
        vm.prank(depositor);
        (uint128 transferAmount, uint128 fee) = FORK_BOB.redeem(vaultId);

        // User received more than deposited.
        assertGt(transferAmount, params.depositAmount, "transfer should exceed deposit");
        assertEq(DAI.balanceOf(depositor) - daiBalanceBefore, transferAmount, "DAI balance should increase by transfer");

        // Fee is ~10% of yield.
        assertGt(fee, 0, "fee should be non-zero");
        uint256 tokensReceived = aaveAdapter.getTokensReceivedAfterUnstaking(vaultId);
        uint256 yieldAmount = tokensReceived - params.depositAmount;
        assertApproxEqRel(fee, yieldAmount * 10 / 100, 0.01e18, "fee should be ~10% of yield");

        // Comptroller collected the fee.
        assertEq(DAI.balanceOf(COMPTROLLER) - comptrollerBalanceBefore, fee, "comptroller should receive the fee");
    }

    /// @dev Two depositors enter the same vault at different times. The earlier depositor should earn a higher
    /// yield rate per token because their scaled balance encodes a lower liquidity index.
    function testForkFuzz_AaveAdapter_MultipleDepositors(Params memory params) public {
        params.depositAmount = uint128(bound(params.depositAmount, 1000e18, 50_000e18));
        params.vaultDuration = uint40(bound(params.vaultDuration, 14 days, 30 days));

        uint256 vaultId = _createDaiVault(params.vaultDuration);
        uint128 depositAmount = params.depositAmount;

        // Depositor 1 enters at t0.
        vm.prank(depositor);
        FORK_BOB.enter(vaultId, depositAmount);
        uint128 scaled1 = aaveAdapter.getYieldBearingTokenBalanceFor(vaultId, depositor);

        // Warp halfway — yield accrues, liquidity index grows.
        uint40 expiry = FORK_BOB.getExpiry(vaultId);
        uint40 midpoint = uint40(block.timestamp) + params.vaultDuration / 2;
        vm.warp(midpoint);

        // Depositor 2 enters at t0 + duration/2 with the same amount.
        vm.prank(depositor2);
        FORK_BOB.enter(vaultId, depositAmount);
        uint128 scaled2 = aaveAdapter.getYieldBearingTokenBalanceFor(vaultId, depositor2);

        // Depositor 2 gets fewer scaled tokens for the same deposit because the index is higher.
        assertGt(scaled1, scaled2, "earlier depositor should have more scaled tokens");

        // Warp past expiry.
        vm.warp(expiry + 1);

        // Unstake explicitly so both redeemers use the same pool of withdrawn tokens.
        FORK_BOB.unstakeTokensViaAdapter(vaultId);
        uint256 tokensReceived = aaveAdapter.getTokensReceivedAfterUnstaking(vaultId);

        // Both deposited the same amount, so total deposited = 2 * depositAmount.
        assertGt(tokensReceived, uint256(depositAmount) * 2, "total should exceed total deposited");

        // Depositor 1 redeems.
        vm.prank(depositor);
        (uint128 transfer1,) = FORK_BOB.redeem(vaultId);

        // Depositor 2 redeems.
        vm.prank(depositor2);
        (uint128 transfer2,) = FORK_BOB.redeem(vaultId);

        // Both should receive more than deposited (positive yield).
        assertGt(transfer1, depositAmount, "depositor1 transfer should exceed deposit");
        assertGt(transfer2, depositAmount, "depositor2 transfer should exceed deposit");

        // Depositor 1 earns more per token because they were in the pool longer.
        uint256 yieldRate1 = (uint256(transfer1) - depositAmount) * 1e18 / depositAmount;
        uint256 yieldRate2 = (uint256(transfer2) - depositAmount) * 1e18 / depositAmount;
        assertGt(yieldRate1, yieldRate2, "earlier depositor should have higher yield rate");
    }

    /// @dev Verifies that getCurrentVaultValue increases after vm.warp without any state-changing interaction.
    function testFork_AaveAdapter_YieldAccrual() public {
        uint128 depositAmount = 10_000e18;
        uint256 vaultId = _createDaiVault(365 days);

        vm.prank(depositor);
        FORK_BOB.enter(vaultId, depositAmount);

        uint256 valueBefore = aaveAdapter.getCurrentVaultValue(vaultId);

        // Warp 90 days. No state-changing calls — pure view function should reflect yield.
        vm.warp(block.timestamp + 90 days);

        uint256 valueAfter = aaveAdapter.getCurrentVaultValue(vaultId);
        assertGt(valueAfter, valueBefore, "value should increase from yield");

        // The yield should be reasonable (0.1% to 50% for 90 days depending on utilization).
        uint256 yieldBps = (valueAfter - valueBefore) * 10_000 / valueBefore;
        assertGt(yieldBps, 0, "yield should be positive");
        assertLt(yieldBps, 5000, "yield should be under 50% for 90 days");
    }
}
