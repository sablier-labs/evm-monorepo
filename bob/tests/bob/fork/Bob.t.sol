// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IWETH9 } from "src/interfaces/external/IWETH9.sol";

import { Fork_Test } from "./Fork.t.sol";

contract Bob_Fork_Test is Fork_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                       PARAMS
    //////////////////////////////////////////////////////////////////////////*/

    struct Params {
        address depositor;
        uint128 depositAmount;
        uint40 vaultDuration;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     FORK TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that requestLidoWithdrawal reverts when the stETH amount is below Lido's minimum.
    function testFork_RevertWhen_StETHAmountBelowMinimum() external {
        // Create a vault with adapter.
        uint256 vaultId = _createForkVaultWithDefaults();

        // Deposit a dust amount (50 wei) which is below Lido's MIN_STETH_WITHDRAWAL_AMOUNT (100 wei).
        uint128 dustAmount = 50;
        address depositor = users.depositor;

        setMsgSender(depositor);
        vm.deal(depositor, 1 ether);
        IWETH9(address(FORK_WETH)).deposit{ value: dustAmount }();
        FORK_WETH.approve(address(forkBob), dustAmount);
        forkBob.enter(vaultId, dustAmount);

        // Warp past expiry.
        vm.warp(getBlockTimestamp() + 2 days);

        // Request Lido withdrawal should revert.
        setMsgSender(address(comptroller));
        vm.expectRevert();
        forkAdapter.requestLidoWithdrawal(vaultId);
    }

    /// @dev Tests the full adapter vault lifecycle using the Curve unstaking path:
    /// create vault → enter → expire → unstake via Curve → redeem.
    function testForkFuzz_CurveUnstaking(Params memory params) external {
        _boundAndSetupParams(params);

        // Step 1: Create vault with adapter.
        uint256 vaultId = _createForkVault(params);

        // Step 2: Deposit WETH into the vault.
        _enterVault(params, vaultId);

        // Verify wstETH was staked.
        uint128 userWstETH = forkAdapter.getYieldBearingTokenBalanceFor(vaultId, params.depositor);
        assertGt(userWstETH, 0, "userWstETH after enter");

        uint128 vaultTotalWstETH = forkAdapter.getTotalYieldBearingTokenBalance(vaultId);
        assertEq(vaultTotalWstETH, userWstETH, "vaultTotalWstETH");

        // Step 3: Warp past expiry so the vault becomes EXPIRED.
        vm.warp(getBlockTimestamp() + params.vaultDuration + 1);

        // Step 4: Unstake via Curve (the default path).
        uint128 amountReceived = forkBob.unstakeTokensViaAdapter(vaultId);
        assertGt(amountReceived, 0, "amountReceived from Curve unstaking");

        // Verify WETH was received by Bob.
        assertGe(FORK_WETH.balanceOf(address(forkBob)), amountReceived, "bob WETH balance after unstake");

        // Step 5: Redeem as the depositor.
        setMsgSender(params.depositor);
        (uint128 transferAmount, uint128 feeDeducted) = forkBob.redeem(vaultId);
        assertGt(transferAmount, 0, "transferAmount after redeem");

        // Verify depositor received WETH.
        assertGe(FORK_WETH.balanceOf(params.depositor), transferAmount, "depositor WETH balance after redeem");

        // Verify the fee was sent to the comptroller (if yield was positive).
        if (feeDeducted > 0) {
            assertGe(FORK_WETH.balanceOf(address(comptroller)), feeDeducted, "comptroller WETH balance after redeem");
        }
    }

    /// @dev Tests the full Lido native withdrawal lifecycle end-to-end:
    /// create vault → enter → expire → request Lido withdrawal → finalize → unstake (claim) → redeem.
    function testForkFuzz_LidoWithdrawalClaimAndRedeem(Params memory params) external {
        _boundAndSetupParams(params);

        // Step 1: Create vault with adapter.
        uint256 vaultId = _createForkVault(params);

        // Step 2: Deposit WETH into the vault.
        _enterVault(params, vaultId);

        uint128 vaultTotalWstETH = forkAdapter.getTotalYieldBearingTokenBalance(vaultId);
        assertGt(vaultTotalWstETH, 0, "vaultTotalWstETH before request");

        // Step 3: Warp past expiry so the vault becomes EXPIRED.
        vm.warp(getBlockTimestamp() + params.vaultDuration + 1);

        // Step 4: Comptroller requests Lido withdrawal.
        setMsgSender(address(comptroller));
        forkAdapter.requestLidoWithdrawal(vaultId);

        // Step 5: Finalize the Lido withdrawal by impersonating the stETH contract (FINALIZE_ROLE holder).
        _finalizeLidoWithdrawals(vaultId);

        // Step 6: Unstake via adapter (claims finalized withdrawals from Lido queue).
        uint128 amountReceived = forkBob.unstakeTokensViaAdapter(vaultId);
        assertGt(amountReceived, 0, "amountReceived from Lido claim");

        // Verify WETH was received by Bob.
        assertGe(FORK_WETH.balanceOf(address(forkBob)), amountReceived, "bob WETH balance after unstake");

        // Step 7: Redeem as the depositor.
        setMsgSender(params.depositor);
        (uint128 transferAmount, uint128 feeDeducted) = forkBob.redeem(vaultId);
        assertGt(transferAmount, 0, "transferAmount after redeem");

        // Verify depositor received WETH.
        assertGe(FORK_WETH.balanceOf(params.depositor), transferAmount, "depositor WETH balance after redeem");

        // Verify the fee was sent to the comptroller (if yield was positive).
        if (feeDeducted > 0) {
            assertGe(FORK_WETH.balanceOf(address(comptroller)), feeDeducted, "comptroller WETH balance after redeem");
        }
    }

    /// @dev Tests that requestLidoWithdrawal correctly interacts with the real Lido withdrawal queue:
    /// create vault → enter → expire → request Lido withdrawal → verify request state.
    function testForkFuzz_LidoWithdrawalRequest(Params memory params) external {
        _boundAndSetupParams(params);

        // Step 1: Create vault with adapter.
        uint256 vaultId = _createForkVault(params);

        // Step 2: Deposit WETH into the vault.
        _enterVault(params, vaultId);

        uint128 vaultTotalWstETH = forkAdapter.getTotalYieldBearingTokenBalance(vaultId);
        assertGt(vaultTotalWstETH, 0, "vaultTotalWstETH before request");

        // Step 3: Warp past expiry so the vault becomes EXPIRED.
        vm.warp(getBlockTimestamp() + params.vaultDuration + 1);

        // Snapshot the adapter's wstETH balance before requesting (other mainnet vaults may hold wstETH).
        uint256 wstETHBefore = IERC20(FORK_WSTETH).balanceOf(address(forkAdapter));

        // Step 4: Comptroller requests Lido withdrawal.
        setMsgSender(address(comptroller));
        forkAdapter.requestLidoWithdrawal(vaultId);

        // Verify request IDs were stored.
        uint256[] memory requestIds = forkAdapter.getLidoWithdrawalRequestIds(vaultId);
        assertGt(requestIds.length, 0, "requestIds length");

        // Verify each request ID is valid (non-zero).
        for (uint256 i; i < requestIds.length; ++i) {
            assertGt(requestIds[i], 0, "requestId non-zero");
        }

        // Verify the vault's wstETH was consumed (unwrapped and submitted to Lido).
        uint256 wstETHAfter = IERC20(FORK_WSTETH).balanceOf(address(forkAdapter));
        assertEq(wstETHBefore - wstETHAfter, vaultTotalWstETH, "adapter wstETH consumed for vault");

        // Verify a duplicate request reverts.
        vm.expectRevert();
        forkAdapter.requestLidoWithdrawal(vaultId);
    }

    /// @dev Tests that requestLidoWithdrawal correctly adjusts the remainder when it falls below
    /// Lido's MIN_STETH_WITHDRAWAL_AMOUNT by borrowing from the second-to-last request.
    function testFork_LidoWithdrawalRemainderAdjustment() external {
        // Create a vault with adapter.
        uint256 vaultId = _createForkVaultWithDefaults();

        // Deposit an amount that will produce a remainder below MIN_STETH_WITHDRAWAL_AMOUNT after splitting.
        // We need total stETH slightly above 1000 ether (MAX_STETH_WITHDRAWAL_AMOUNT).
        // Due to stETH rebasing, we deposit slightly more than 1000 ether + a small amount.
        uint128 depositAmount = 1000 ether + 10;
        address depositor = users.depositor;

        setMsgSender(depositor);
        vm.deal(depositor, uint256(depositAmount) + 1 ether);
        IWETH9(address(FORK_WETH)).deposit{ value: depositAmount }();
        FORK_WETH.approve(address(forkBob), depositAmount);
        forkBob.enter(vaultId, depositAmount);

        // Snapshot the adapter's wstETH balance before requesting.
        uint128 vaultTotalWstETH = forkAdapter.getTotalYieldBearingTokenBalance(vaultId);
        uint256 wstETHBefore = IERC20(FORK_WSTETH).balanceOf(address(forkAdapter));

        // Warp past expiry.
        vm.warp(getBlockTimestamp() + 2 days);

        // Request Lido withdrawal — should succeed with remainder adjustment.
        setMsgSender(address(comptroller));
        forkAdapter.requestLidoWithdrawal(vaultId);

        // Verify request IDs were stored (should be 2 requests due to splitting).
        uint256[] memory requestIds = forkAdapter.getLidoWithdrawalRequestIds(vaultId);
        assertEq(requestIds.length, 2, "requestIds length should be 2");

        // Verify each request ID is valid.
        for (uint256 i; i < requestIds.length; ++i) {
            assertGt(requestIds[i], 0, "requestId non-zero");
        }

        // Verify the vault's wstETH was fully consumed.
        uint256 wstETHAfter = IERC20(FORK_WSTETH).balanceOf(address(forkAdapter));
        assertEq(wstETHBefore - wstETHAfter, vaultTotalWstETH, "adapter wstETH consumed for vault");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Bounds and validates fuzz parameters.
    function _boundAndSetupParams(Params memory params) private view {
        // Bound the depositor to a valid address.
        vm.assume(params.depositor != address(0));
        vm.assume(params.depositor != address(forkBob) && params.depositor != address(forkAdapter));
        vm.assume(params.depositor != address(comptroller));
        vm.assume(params.depositor != FORK_CURVE_POOL && params.depositor != FORK_STETH);
        vm.assume(params.depositor != FORK_WSTETH && params.depositor != FORK_LIDO_WITHDRAWAL_QUEUE);

        // Bound deposit amount: minimum 0.01 WETH, maximum 100 WETH.
        params.depositAmount = boundUint128(params.depositAmount, 0.01 ether, 100 ether);

        // Bound vault duration: 1 day to 30 days.
        params.vaultDuration = boundUint40(params.vaultDuration, 1 days, 30 days);
    }

    /// @dev Creates a vault with an adapter on the fork using the real Chainlink ETH/USD oracle.
    function _createForkVault(Params memory params) private returns (uint256 vaultId) {
        // Get the current ETH price from the real Chainlink oracle.
        (, int256 answer,,,) = FORK_ETH_USD_ORACLE.latestRoundData();
        uint128 currentPrice = uint128(uint256(answer));

        // Set target price 50% above current price (ensures vault won't settle, only expire).
        uint128 targetPrice = currentPrice * 3 / 2;

        // Set expiry based on fuzzed duration.
        uint40 expiry = getBlockTimestamp() + params.vaultDuration;

        vaultId = forkBob.createVault({
            token: FORK_WETH,
            oracle: FORK_ETH_USD_ORACLE,
            expiry: expiry,
            targetPrice: targetPrice
        });
    }

    /// @dev Creates a vault with default parameters for non-fuzz fork tests.
    function _createForkVaultWithDefaults() private returns (uint256 vaultId) {
        (, int256 answer,,,) = FORK_ETH_USD_ORACLE.latestRoundData();
        uint128 currentPrice = uint128(uint256(answer));
        uint128 targetPrice = currentPrice * 3 / 2;
        uint40 expiry = getBlockTimestamp() + 1 days;

        vaultId = forkBob.createVault({
            token: FORK_WETH,
            oracle: FORK_ETH_USD_ORACLE,
            expiry: expiry,
            targetPrice: targetPrice
        });
    }

    /// @dev Deposits WETH into a vault as the depositor.
    function _enterVault(Params memory params, uint256 vaultId) private {
        // Set the depositor as the caller first (setMsgSender deals 1 ETH), then deal the actual amount needed.
        setMsgSender(params.depositor);
        vm.deal(params.depositor, uint256(params.depositAmount) + 1 ether);
        IWETH9(address(FORK_WETH)).deposit{ value: params.depositAmount }();

        // Approve Bob to spend WETH.
        FORK_WETH.approve(address(forkBob), params.depositAmount);

        // Enter the vault.
        forkBob.enter(vaultId, params.depositAmount);
    }
}
