// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierAaveAdapter } from "src/interfaces/ISablierAaveAdapter.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { SablierAaveAdapter } from "src/SablierAaveAdapter.sol";

import { Fork_Test } from "./Fork.t.sol";

contract AaveAdapter_Fork_Test is Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                       PARAMS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        address depositor;
        uint128 depositAmount;
        uint40 vaultDuration;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierAaveAdapter internal forkAaveAdapter;

    /*//////////////////////////////////////////////////////////////////////////
                                       SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Fork_Test.setUp();

        // Deploy a fresh Aave adapter against real Aave V3 contracts.
        forkAaveAdapter = new SablierAaveAdapter({
            aavePoolAddressesProvider: FORK_AAVE_POOL_ADDRESSES_PROVIDER,
            initialComptroller: address(comptroller),
            initialYieldFee: UD60x18.wrap(0.1e18),
            sablierBob: address(forkBob)
        });
        vm.label(address(forkAaveAdapter), "ForkSablierAaveAdapter");

        // Register the Aave adapter as the default adapter for WBTC.
        vm.prank(address(comptroller));
        forkBob.setDefaultAdapter(FORK_WBTC, ISablierBobAdapter(address(forkAaveAdapter)));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     FORK TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests the full Aave adapter vault lifecycle:
    /// create WBTC vault → enter → expire → unstake from Aave → redeem.
    function testForkFuzz_AaveLifecycle(Params memory params) external {
        _boundAndSetupParams(params);

        // Step 1: Create a WBTC vault with the Aave adapter.
        uint256 vaultId = _createAaveForkVault(params);

        // Step 2: Deposit WBTC into the vault.
        _enterVault(params, vaultId);

        // Verify aTokens were tracked in the adapter.
        uint128 userATokenBalance = forkAaveAdapter.getYieldBearingTokenBalanceFor(vaultId, params.depositor);
        assertGt(userATokenBalance, 0, "userATokenBalance after enter");

        uint128 vaultTotalATokenBalance = forkAaveAdapter.getTotalYieldBearingTokenBalance(vaultId);
        assertEq(vaultTotalATokenBalance, userATokenBalance, "vaultTotalATokenBalance");

        // Step 3: Warp past expiry so the vault becomes EXPIRED.
        vm.warp(getBlockTimestamp() + params.vaultDuration + 1);

        // Step 4: Unstake from Aave (withdraws WBTC from Aave to Bob).
        uint128 amountReceived = forkBob.unstakeTokensViaAdapter(vaultId);
        assertGt(amountReceived, 0, "amountReceived from Aave unstaking");

        // Verify WBTC was received by Bob.
        assertGe(FORK_WBTC.balanceOf(address(forkBob)), amountReceived, "bob WBTC balance after unstake");

        // Step 5: Redeem as the depositor.
        setMsgSender(params.depositor);
        (uint128 transferAmount, uint128 feeDeducted) = forkBob.redeem(vaultId);
        assertGt(transferAmount, 0, "transferAmount after redeem");

        // Verify depositor received WBTC.
        assertGe(FORK_WBTC.balanceOf(params.depositor), transferAmount, "depositor WBTC balance after redeem");

        // Verify the fee was sent to the comptroller (if yield was positive).
        if (feeDeducted > 0) {
            assertGe(FORK_WBTC.balanceOf(address(comptroller)), feeDeducted, "comptroller WBTC balance after redeem");
        }
    }

    /// @dev Tests the Aave adapter with two depositors to verify proportional redemption.
    function testForkFuzz_AaveMultipleDepositors(Params memory params) external {
        _boundAndSetupParams(params);

        // Step 1: Create a WBTC vault with the Aave adapter.
        uint256 vaultId = _createAaveForkVault(params);

        // Step 2: First depositor enters.
        _enterVault(params, vaultId);

        // Step 3: Second depositor enters with the same amount.
        address secondDepositor = makeAddr("SecondDepositor");
        vm.label(secondDepositor, "SecondDepositor");
        deal(address(FORK_WBTC), secondDepositor, params.depositAmount);
        setMsgSender(secondDepositor);
        FORK_WBTC.approve(address(forkBob), params.depositAmount);
        forkBob.enter(vaultId, params.depositAmount);

        // Verify both users have aToken balances.
        uint128 firstUserBalance = forkAaveAdapter.getYieldBearingTokenBalanceFor(vaultId, params.depositor);
        uint128 secondUserBalance = forkAaveAdapter.getYieldBearingTokenBalanceFor(vaultId, secondDepositor);
        assertGt(firstUserBalance, 0, "firstUser aTokenBalance");
        assertGt(secondUserBalance, 0, "secondUser aTokenBalance");

        // Step 4: Warp past expiry.
        vm.warp(getBlockTimestamp() + params.vaultDuration + 1);

        // Step 5: Unstake from Aave.
        uint128 amountReceived = forkBob.unstakeTokensViaAdapter(vaultId);
        assertGt(amountReceived, 0, "amountReceived from Aave unstaking");

        // Step 6: Both depositors redeem.
        setMsgSender(params.depositor);
        (uint128 firstTransfer,) = forkBob.redeem(vaultId);
        assertGt(firstTransfer, 0, "firstDepositor transferAmount");

        setMsgSender(secondDepositor);
        (uint128 secondTransfer,) = forkBob.redeem(vaultId);
        assertGt(secondTransfer, 0, "secondDepositor transferAmount");

        // Both depositors should receive approximately equal amounts (same deposit, same duration).
        uint128 tolerance = params.depositAmount / 100; // 1% tolerance for rounding.
        assertApproxEqAbs(firstTransfer, secondTransfer, tolerance, "proportional redemption");
    }

    /// @dev Tests that Aave yield accrues over time and is reflected in the unstaked amount.
    function testForkFuzz_AaveYieldAccrual(Params memory params) external {
        _boundAndSetupParams(params);

        // Use a longer vault duration to let yield accrue.
        params.vaultDuration = boundUint40(params.vaultDuration, 30 days, 90 days);

        // Step 1: Create vault and deposit.
        uint256 vaultId = _createAaveForkVault(params);
        _enterVault(params, vaultId);

        // Snapshot the aToken balance right after staking.
        uint128 aTokenBalanceAfterStake = forkAaveAdapter.getTotalYieldBearingTokenBalance(vaultId);

        // Step 2: Warp past expiry (30-90 days of yield accrual).
        vm.warp(getBlockTimestamp() + params.vaultDuration + 1);

        // The aToken balance should have grown due to accrued interest.
        uint128 aTokenBalanceAtExpiry = forkAaveAdapter.getTotalYieldBearingTokenBalance(vaultId);
        assertGe(aTokenBalanceAtExpiry, aTokenBalanceAfterStake, "aToken balance should grow with yield");

        // Step 3: Unstake and verify the received amount is at least the deposit.
        uint128 amountReceived = forkBob.unstakeTokensViaAdapter(vaultId);
        assertGe(amountReceived, params.depositAmount, "unstaked amount >= deposit (yield accrued)");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Bounds and validates fuzz parameters for WBTC vaults.
    function _boundAndSetupParams(Params memory params) private view {
        // Bound the depositor to a valid address.
        vm.assume(params.depositor != address(0));
        vm.assume(params.depositor != address(forkBob) && params.depositor != address(forkAaveAdapter));
        vm.assume(params.depositor != address(comptroller));

        // Bound deposit amount: 0.001 WBTC (1e5) to 10 WBTC (10e8).
        params.depositAmount = boundUint128(params.depositAmount, 0.001e8, 10e8);

        // Bound vault duration: 1 day to 30 days.
        params.vaultDuration = boundUint40(params.vaultDuration, 1 days, 30 days);
    }

    /// @dev Creates a WBTC vault with the Aave adapter on the fork using the real Chainlink ETH/USD oracle.
    function _createAaveForkVault(Params memory params) private returns (uint256 vaultId) {
        // Get the current ETH price from the real Chainlink oracle.
        (, int256 answer,,,) = FORK_ETH_USD_ORACLE.latestRoundData();
        uint128 currentPrice = uint128(uint256(answer));

        // Set target price 50% above current price (ensures vault won't settle, only expire).
        uint128 targetPrice = currentPrice * 3 / 2;

        // Set expiry based on fuzzed duration.
        uint40 expiry = getBlockTimestamp() + params.vaultDuration;

        vaultId = forkBob.createVault({
            token: FORK_WBTC,
            oracle: FORK_ETH_USD_ORACLE,
            expiry: expiry,
            targetPrice: targetPrice
        });
    }

    /// @dev Deposits WBTC into a vault as the depositor.
    function _enterVault(Params memory params, uint256 vaultId) private {
        // Deal WBTC to the depositor.
        deal(address(FORK_WBTC), params.depositor, params.depositAmount);

        // Approve Bob to spend WBTC.
        setMsgSender(params.depositor);
        FORK_WBTC.approve(address(forkBob), params.depositAmount);

        // Enter the vault.
        forkBob.enter(vaultId, params.depositAmount);
    }
}
