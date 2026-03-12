// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ChainlinkOracleWith18Decimals } from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { SablierBob } from "src/SablierBob.sol";
import { SablierLidoAdapter } from "src/SablierLidoAdapter.sol";
import { MockCurvePool } from "./mocks/MockCurvePool.sol";
import { MockLidoWithdrawalQueue } from "./mocks/MockLidoWithdrawalQueue.sol";
import { MockStETH } from "./mocks/MockStETH.sol";
import { MockWETH } from "./mocks/MockWETH.sol";
import { MockWstETH } from "./mocks/MockWstETH.sol";
import { Assertions } from "./utils/Assertions.sol";
import { Modifiers } from "./utils/Modifiers.sol";
import { Users, VaultIds } from "./utils/Types.sol";
import { Utils } from "./utils/Utils.sol";

/// @notice Base test contract with common logic needed by all tests.
abstract contract Base_Test is Assertions, Modifiers, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;
    VaultIds internal vaultIds;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierLidoAdapter internal adapter;
    ISablierBob internal bob;
    IBobVaultShare internal defaultShareToken;

    // External protocol mocks (Lido ecosystem).
    MockCurvePool internal curvePool;
    MockLidoWithdrawalQueue internal lidoWithdrawalQueue;
    MockStETH internal steth;
    ChainlinkOracleWith18Decimals internal stETHETHOracle;
    MockWETH internal weth;
    MockWstETH internal wstEth;

    /*//////////////////////////////////////////////////////////////////////////
                                       SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        EvmUtilsBase.setUp();

        // Deploy external Lido/Curve mocks.
        deployExternalMocks();

        // Push the WETH to the list of tokens.
        tokens.push(weth);

        // Deploy the protocol.
        deployProtocol();

        // Set modifier variables.
        setBob(address(bob));

        // Create test users.
        createTestUsers();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Computes the address of the next share token that will be deployed by Bob.
    function computeNextShareTokenAddress() internal view returns (IBobVaultShare) {
        return IBobVaultShare(vm.computeCreateAddress(address(bob), vm.getNonce(address(bob))));
    }

    /// @dev Create users for testing.
    function createTestUsers() internal {
        address[] memory spenders = new address[](1);
        spenders[0] = address(bob);

        // Create test users.
        users.alice = createUser("Alice", spenders);
        users.eve = createUser("Eve", spenders);
        users.depositor = createUser("Depositor", spenders);
        users.newDepositor = createUser("New Depositor", spenders);

        // Deal ETH tokens to the depositor and deposit them into WETH.
        setMsgSender(users.depositor);
        vm.deal(users.depositor, 10_000 ether);
        IWETH9(address(weth)).deposit{ value: 10_000 ether }();

        // Approve the Bob contract to spend the depositor's WETH.
        weth.approve(address(bob), MAX_UINT128);
    }

    /// @dev Deploys mocks for external protocols.
    function deployExternalMocks() internal {
        weth = new MockWETH();
        steth = new MockStETH();
        wstEth = new MockWstETH(address(steth));
        curvePool = new MockCurvePool(address(steth));
        lidoWithdrawalQueue = new MockLidoWithdrawalQueue();

        // Deploy a stETH/ETH oracle mock returning ~1:1 (1e18 in 18 decimals).
        stETHETHOracle = new ChainlinkOracleWith18Decimals();
        stETHETHOracle.setPrice(STETH_ETH_ORACLE_PRICE);

        // Fund Curve pool with ETH for swaps.
        vm.deal(address(curvePool), 10_000 ether);

        // Fund Lido withdrawal queue with ETH for claims.
        vm.deal(address(lidoWithdrawalQueue), 10_000 ether);
    }

    /// @dev Deploys the Bob protocol.
    function deployProtocol() internal {
        bob = new SablierBob(address(comptroller));
        vm.label({ account: address(bob), newLabel: "SablierBob" });

        adapter = new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            lidoWithdrawalQueue: address(lidoWithdrawalQueue),
            stETH: address(steth),
            stETH_ETH_Oracle: address(stETHETHOracle),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: SLIPPAGE_TOLERANCE,
            initialYieldFee: YIELD_FEE
        });
        vm.label({ account: address(adapter), newLabel: "SablierLidoAdapter" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VAULT CREATION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates a default vault.
    function createDefaultVault() internal returns (uint256 vaultId) {
        vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    /// @dev Creates a vault with an adapter configured.
    function createVaultWithAdapter() internal returns (uint256 vaultId) {
        // Set the default adapter for WETH.
        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(weth, adapter);

        // Create the vault.
        vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }
}
