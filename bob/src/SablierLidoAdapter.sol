// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";
import { Comptrollerable } from "@sablier/evm-utils/src/Comptrollerable.sol";
import { SafeOracle } from "@sablier/evm-utils/src/libraries/SafeOracle.sol";

import { ICurveStETHPool } from "./interfaces/external/ICurveStETHPool.sol";
import { ILidoWithdrawalQueue } from "./interfaces/external/ILidoWithdrawalQueue.sol";
import { IStETH } from "./interfaces/external/IStETH.sol";
import { IWETH9 } from "./interfaces/external/IWETH9.sol";
import { IWstETH } from "./interfaces/external/IWstETH.sol";
import { ISablierBobAdapter } from "./interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "./interfaces/ISablierLidoAdapter.sol";
import { Errors } from "./libraries/Errors.sol";

/// @title SablierLidoAdapter
/// @notice Lido yield adapter for the SablierBob protocol.
/// @dev This adapter stakes WETH as wstETH to earn Lido staking rewards.
contract SablierLidoAdapter is
    Comptrollerable, // 1 inherited component
    ERC165, // 1 inherited component
    ISablierLidoAdapter // 2 inherited components
{
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLidoAdapter
    address public immutable override CURVE_POOL;

    /// @inheritdoc ISablierLidoAdapter
    address public immutable override LIDO_WITHDRAWAL_QUEUE;

    /// @inheritdoc ISablierBobAdapter
    UD60x18 public constant override MAX_FEE = UD60x18.wrap(0.2e18);

    /// @inheritdoc ISablierLidoAdapter
    UD60x18 public constant override MAX_SLIPPAGE_TOLERANCE = UD60x18.wrap(0.05e18);

    /// @inheritdoc ISablierLidoAdapter
    address public immutable override STETH;

    /// @inheritdoc ISablierLidoAdapter
    address public immutable override STETH_ETH_ORACLE;

    /// @inheritdoc ISablierLidoAdapter
    address public immutable override WETH;

    /// @inheritdoc ISablierLidoAdapter
    address public immutable override WSTETH;

    /// @inheritdoc ISablierBobAdapter
    address public immutable override SABLIER_BOB;

    /*//////////////////////////////////////////////////////////////////////////
                                   PUBLIC STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBobAdapter
    UD60x18 public override feeOnYield;

    /// @inheritdoc ISablierLidoAdapter
    UD60x18 public override slippageTolerance;

    /*//////////////////////////////////////////////////////////////////////////
                                  INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Lido withdrawal request IDs for each vault.
    mapping(uint256 vaultId => uint256[] requestIds) internal _lidoWithdrawalRequestIds;

    /// @dev wstETH amount held for each user in each vault.
    mapping(uint256 vaultId => mapping(address user => uint128 wstETHAmount)) internal _userWstETH;

    /// @dev Total wstETH amount held in each vault.
    mapping(uint256 vaultId => uint128 totalWstETH) internal _vaultTotalWstETH;

    /// @dev Yield fee snapshotted for each vault at creation time.
    mapping(uint256 vaultId => UD60x18 fee) internal _vaultYieldFee;

    /// @dev Total WETH received after unstaking all tokens in a vault.
    mapping(uint256 vaultId => uint128 wethReceived) internal _wethReceivedAfterUnstaking;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deploys the Lido adapter.
    /// @param initialComptroller The address of the initial comptroller contract.
    /// @param sablierBob The address of the SablierBob contract.
    /// @param curvePool The address of the Curve stETH/ETH pool.
    /// @param lidoWithdrawalQueue The address of the Lido withdrawal queue contract.
    /// @param initialSlippageTolerance The initial slippage tolerance for Curve swaps as UD60x18.
    /// @param initialYieldFee The initial yield fee as UD60x18.
    constructor(
        address initialComptroller,
        address sablierBob,
        address curvePool,
        address lidoWithdrawalQueue,
        address stETH,
        address stETH_ETH_Oracle,
        address wETH,
        address wstETH,
        UD60x18 initialSlippageTolerance,
        UD60x18 initialYieldFee
    )
        Comptrollerable(initialComptroller)
    {
        // Check: the slippage tolerance is not too high.
        if (initialSlippageTolerance.gt(MAX_SLIPPAGE_TOLERANCE)) {
            revert Errors.SablierLidoAdapter_SlippageToleranceTooHigh(initialSlippageTolerance, MAX_SLIPPAGE_TOLERANCE);
        }

        // Check: the yield fee is not too high.
        if (initialYieldFee.gt(MAX_FEE)) {
            revert Errors.SablierLidoAdapter_YieldFeeTooHigh(initialYieldFee, MAX_FEE);
        }

        SABLIER_BOB = sablierBob;
        CURVE_POOL = curvePool;
        LIDO_WITHDRAWAL_QUEUE = lidoWithdrawalQueue;
        STETH = stETH;
        STETH_ETH_ORACLE = stETH_ETH_Oracle;
        WETH = wETH;
        WSTETH = wstETH;

        // Effect: set the initial slippage tolerance.
        slippageTolerance = initialSlippageTolerance;

        // Effect: set the initial yield fee.
        feeOnYield = initialYieldFee;

        // Approve wstETH contract to spend stETH, required for wrapping.
        IStETH(STETH).approve(WSTETH, type(uint128).max);

        // Approve Curve pool to spend stETH, required for unwrapping.
        IStETH(STETH).approve(CURVE_POOL, type(uint128).max);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if the caller is not SablierBob.
    modifier onlySablierBob() {
        if (msg.sender != SABLIER_BOB) {
            revert Errors.SablierLidoAdapter_OnlySablierBob(msg.sender, SABLIER_BOB);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierLidoAdapter
    function getLidoWithdrawalRequestIds(uint256 vaultId) external view override returns (uint256[] memory) {
        return _lidoWithdrawalRequestIds[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getTotalYieldBearingTokenBalance(uint256 vaultId) external view override returns (uint128) {
        return _vaultTotalWstETH[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getVaultYieldFee(uint256 vaultId) external view override returns (UD60x18) {
        return _vaultYieldFee[vaultId];
    }

    /// @inheritdoc ISablierLidoAdapter
    function getWethReceivedAfterUnstaking(uint256 vaultId) external view override returns (uint256) {
        return _wethReceivedAfterUnstaking[vaultId];
    }

    /// @inheritdoc ISablierBobAdapter
    function getYieldBearingTokenBalanceFor(uint256 vaultId, address user) external view override returns (uint128) {
        return _userWstETH[vaultId][user];
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ISablierBobAdapter).interfaceId
            || interfaceId == type(ISablierLidoAdapter).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierBobAdapter
    function processRedemption(
        uint256 vaultId,
        address user,
        uint128 shareBalance
    )
        external
        override
        onlySablierBob
        returns (uint128 transferAmount, uint128 feeAmountDeductedFromYield)
    {
        // Get total amount of wstETH in the vault before unstaking.
        uint256 totalWstETH = _vaultTotalWstETH[vaultId];

        // Get total amount of WETH received after unstaking all tokens in the vault.
        uint256 totalWeth = _wethReceivedAfterUnstaking[vaultId];

        // If total wstETH or total WETH received is zero, return zero.
        if (totalWstETH == 0 || totalWeth == 0) {
            return (0, 0);
        }

        // Get wstETH allocated to the user before unstaking.
        uint256 userWstETH = _userWstETH[vaultId][user];

        // Calculate user's proportional share of WETH.
        uint128 userWethShare = (userWstETH * totalWeth / totalWstETH).toUint128();

        // If the user's share of WETH is greater than the user's vault share, the yield is positive and we need to
        // calculate the fee.
        if (userWethShare > shareBalance) {
            uint128 yieldAmount = userWethShare - shareBalance;

            // Calculate the fee.
            feeAmountDeductedFromYield = ud(yieldAmount).mul(_vaultYieldFee[vaultId]).intoUint128();
            transferAmount = userWethShare - feeAmountDeductedFromYield;
        }
        // Otherwise, the yield is negative or zero, so no fee is applicable.
        else {
            transferAmount = userWethShare;
        }

        // Effect: clear the user's wstETH balance.
        delete _userWstETH[vaultId][user];
    }

    /// @inheritdoc ISablierBobAdapter
    function registerVault(uint256 vaultId) external override onlySablierBob {
        // Effect: snapshot the current global yield fee for this vault.
        _vaultYieldFee[vaultId] = feeOnYield;
    }

    /// @inheritdoc ISablierLidoAdapter
    function requestLidoWithdrawal(uint256 vaultId) external override onlyComptroller {
        // Check: Lido withdrawal has not already been requested for this vault.
        if (_lidoWithdrawalRequestIds[vaultId].length > 0) {
            revert Errors.SablierLidoAdapter_LidoWithdrawalAlreadyRequested(vaultId);
        }

        // Get total wstETH in the vault.
        uint128 totalWstETH = _vaultTotalWstETH[vaultId];

        // Check: total wstETH is not zero.
        if (totalWstETH == 0) {
            revert Errors.SablierLidoAdapter_NoWstETHToWithdraw(vaultId);
        }

        // Interaction: Unwrap wstETH to get stETH.
        uint256 stETHAmount = IWstETH(WSTETH).unwrap(totalWstETH);

        // Get the maximum amount that can be withdrawn in a single request.
        uint256 maxAmountPerRequest = ILidoWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).MAX_STETH_WITHDRAWAL_AMOUNT();

        // Declare amounts array.
        uint256[] memory amounts;

        // If the total amount to be withdrawn is greater than the maximum amount per request, split it into multiple
        // requests.
        if (stETHAmount > maxAmountPerRequest) {
            // Calculate the total number of requests required to withdraw the full amount using the ceiling division.
            uint256 totalRequests = (stETHAmount + maxAmountPerRequest - 1) / maxAmountPerRequest;

            // Initialize array length to the total number of requests.
            amounts = new uint256[](totalRequests);

            // Assign amounts for each request except the last one.
            uint256 lastIndex = totalRequests - 1;
            for (uint256 i; i < lastIndex; ++i) {
                amounts[i] = maxAmountPerRequest;
            }

            // Assign the remaining amount to the last request.
            amounts[lastIndex] = stETHAmount - maxAmountPerRequest * lastIndex;
        }
        // Otherwise, its just one request.
        else {
            // Initialize array length to 1.
            amounts = new uint256[](1);
            amounts[0] = stETHAmount;
        }

        // Interaction: Approve Lido withdrawal queue to spend the exact stETH amount.
        IStETH(STETH).approve(LIDO_WITHDRAWAL_QUEUE, stETHAmount);

        // Interaction: Submit stETH to Lido's withdrawal queue.
        uint256[] memory requestIds =
            ILidoWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).requestWithdrawals(amounts, address(this));

        // Effect: store request IDs for later claiming (also disables the Curve path for this vault).
        _lidoWithdrawalRequestIds[vaultId] = requestIds;

        // Log the event.
        emit RequestLidoWithdrawal(vaultId, msg.sender, totalWstETH, stETHAmount, requestIds);
    }

    /// @inheritdoc ISablierLidoAdapter
    function setSlippageTolerance(UD60x18 newTolerance) external override onlyComptroller {
        // Check: the slippage tolerance does not exceed MAX_SLIPPAGE_TOLERANCE.
        if (newTolerance.gt(MAX_SLIPPAGE_TOLERANCE)) {
            revert Errors.SablierLidoAdapter_SlippageToleranceTooHigh(newTolerance, MAX_SLIPPAGE_TOLERANCE);
        }

        // Cache the current slippage tolerance.
        UD60x18 previousTolerance = slippageTolerance;

        // Effect: set the new slippage tolerance.
        slippageTolerance = newTolerance;

        // Log the event.
        emit SetSlippageTolerance(previousTolerance, newTolerance);
    }

    /// @inheritdoc ISablierBobAdapter
    function setYieldFee(UD60x18 newFee) external override onlyComptroller {
        // Check: the new fee does not exceed MAX_FEE.
        if (newFee.gt(MAX_FEE)) {
            revert Errors.SablierLidoAdapter_YieldFeeTooHigh(newFee, MAX_FEE);
        }

        UD60x18 previousFee = feeOnYield;

        // Effect: set the new fee.
        feeOnYield = newFee;

        // Log the event.
        emit SetYieldFee(previousFee, newFee);
    }

    /// @inheritdoc ISablierBobAdapter
    function stake(uint256 vaultId, address user, uint256 amount) external override onlySablierBob {
        // Interaction: Unwrap WETH into ETH.
        IWETH9(WETH).withdraw(amount);

        // Interaction: Stake ETH to get stETH.
        IStETH(STETH).submit{ value: amount }({ referral: address(comptroller) });

        // Get the balance of stETH held by the adapter.
        uint256 stETHBalance = IStETH(STETH).balanceOf(address(this));

        // Interaction: Wrap stETH into wstETH.
        uint128 wstETHAmount = IWstETH(WSTETH).wrap(stETHBalance).toUint128();

        // Effect: track user's wstETH.
        _userWstETH[vaultId][user] += wstETHAmount;
        _vaultTotalWstETH[vaultId] += wstETHAmount;

        // Log the event.
        emit Stake(vaultId, user, amount, wstETHAmount);
    }

    /// @inheritdoc ISablierBobAdapter
    function unstakeFullAmount(uint256 vaultId)
        external
        override
        onlySablierBob
        returns (uint128 totalWstETH, uint128 amountReceivedFromUnstaking)
    {
        // Get total amount of wstETH in the vault.
        totalWstETH = _vaultTotalWstETH[vaultId];

        // If a Lido withdrawal was requested, claim from the withdrawal queue.
        if (_lidoWithdrawalRequestIds[vaultId].length > 0) {
            amountReceivedFromUnstaking = _claimLidoWithdrawals(vaultId);
        }
        // Otherwise, swap via Curve.
        else {
            amountReceivedFromUnstaking = _wstETHToWeth(totalWstETH);
        }

        // Effect: store the total WETH received for redemption calculations.
        _wethReceivedAfterUnstaking[vaultId] = amountReceivedFromUnstaking;

        // Interaction: Transfer WETH to SablierBob for distribution.
        IERC20(WETH).safeTransfer(SABLIER_BOB, amountReceivedFromUnstaking);

        // Log the event.
        emit UnstakeFullAmount({
            vaultId: vaultId,
            totalStakedAmount: totalWstETH,
            amountReceivedFromUnstaking: amountReceivedFromUnstaking
        });
    }

    /// @inheritdoc ISablierBobAdapter
    function updateStakedTokenBalance(
        uint256 vaultId,
        address from,
        address to,
        uint256 shareAmountTransferred,
        uint256 userShareBalanceBeforeTransfer
    )
        external
        override
        onlySablierBob
    {
        // Check: the user's balance is not zero.
        if (userShareBalanceBeforeTransfer == 0) {
            revert Errors.SablierLidoAdapter_UserBalanceZero(vaultId, from);
        }

        // Calculate proportional wstETH to transfer.
        uint256 fromWstETH = _userWstETH[vaultId][from];

        // Calculate the portion of wstETH to transfer.
        uint128 wstETHToTransfer = (fromWstETH * shareAmountTransferred / userShareBalanceBeforeTransfer).toUint128();

        // Check: the wstETH transfer amount is not zero.
        if (wstETHToTransfer == 0) {
            revert Errors.SablierLidoAdapter_WstETHTransferAmountZero(vaultId, from, to);
        }

        // Effect: move wstETH from sender to recipient.
        _userWstETH[vaultId][from] -= wstETHToTransfer;
        _userWstETH[vaultId][to] += wstETHToTransfer;

        // Log the event.
        emit TransferStakedTokens(vaultId, from, to, wstETHToTransfer);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          PRIVATE STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Claims finalized Lido withdrawals for a vault and wraps the received ETH into WETH.
    function _claimLidoWithdrawals(uint256 vaultId) private returns (uint128 wethReceived) {
        uint256[] memory requestIds = _lidoWithdrawalRequestIds[vaultId];

        // Interaction: Since Lido processes withdrawals in batches, we need to find the number of total finalized
        // batches occurred so far. This is used in the next step.
        uint256 lastIndex = ILidoWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).getLastCheckpointIndex();

        // Interaction: search the request IDs in all the finalized batches. If any request ID is not finalized, the
        // corresponding hint will be zero.
        uint256[] memory hints =
            ILidoWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).findCheckpointHints(requestIds, 1, lastIndex);

        // Get the ETH balance before claiming.
        uint256 ethBefore = address(this).balance;

        // Interaction: Claim all request IDs. It will revert if any request ID is not finalized.
        ILidoWithdrawalQueue(LIDO_WITHDRAWAL_QUEUE).claimWithdrawals(requestIds, hints);

        // Calculate the ETH received from claiming.
        uint256 ethReceived = address(this).balance - ethBefore;

        // Interaction: Wrap ETH to get WETH.
        IWETH9(WETH).deposit{ value: ethReceived }();

        return ethReceived.toUint128();
    }

    /// @dev Converts wstETH to WETH using Curve exchange, with oracle-based slippage protection.
    function _wstETHToWeth(uint128 wstETHAmount) private returns (uint128 wethReceived) {
        // Interaction: Unwrap wstETH to get stETH.
        uint256 stETHAmount = IWstETH(WSTETH).unwrap(wstETHAmount);

        // Get the stETH/ETH price from the Chainlink oracle in its native 18 decimals.
        (uint128 oraclePrice,,) =
            SafeOracle.safeOraclePrice({ oracle: AggregatorV3Interface(STETH_ETH_ORACLE), normalize: false });

        // Calculate the fair ETH output using the oracle price as a manipulation-resistant reference.
        uint256 fairEthOut = stETHAmount * oraclePrice / 1e18;

        // Calculate minimum acceptable output with slippage tolerance.
        uint256 minEthOut = ud(fairEthOut).mul(UNIT.sub(slippageTolerance)).unwrap();

        // Interaction: Swap stETH for ETH via Curve.
        uint256 ethReceived = ICurveStETHPool(CURVE_POOL).exchange(1, 0, stETHAmount, minEthOut);

        // Check: the amount of ETH received is greater than the minimum acceptable output.
        if (ethReceived < minEthOut) {
            revert Errors.SablierLidoAdapter_SlippageExceeded(minEthOut, ethReceived);
        }

        uint128 ethReceivedU128 = ethReceived.toUint128();

        // Interaction: Wrap ETH to get WETH.
        IWETH9(WETH).deposit{ value: ethReceived }();

        return ethReceivedU128;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      RECEIVE
    //////////////////////////////////////////////////////////////////////////*/

    receive() external payable { }
}
