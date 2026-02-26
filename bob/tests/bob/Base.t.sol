// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { BaseTest as EvmBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { SablierBob } from "src/SablierBob.sol";
import { SablierLidoAdapter } from "src/SablierLidoAdapter.sol";

import { MockWETH9, MockCurvePool, MockStETH, MockWstETH } from "./mocks/MocksAdapter.sol";
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
    MockStETH internal steth;
    MockWETH9 internal weth;
    MockWstETH internal wstEth;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        EvmBase.setUp();

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

        // Warp to Feb 1, 2026 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2026 });
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

        // Fund the depositor with WETH.
        setMsgSender(users.depositor);
        vm.deal(users.depositor, 1000 ether);
        IWETH9(address(weth)).deposit{ value: 1000 ether }();
        weth.approve(address(bob), type(uint256).max);
    }

    /// @dev Deploys the Bob protocol.
    function deployProtocol() internal {
        bob = new SablierBob(address(comptroller));
        vm.label({ account: address(bob), newLabel: "SablierBob" });

        adapter = new SablierLidoAdapter({
            initialComptroller: address(comptroller),
            sablierBob: address(bob),
            curvePool: address(curvePool),
            stETH: address(steth),
            wETH: address(weth),
            wstETH: address(wstEth),
            initialSlippageTolerance: SLIPPAGE_TOLERANCE,
            initialYieldFee: YIELD_FEE
        });
        vm.label({ account: address(adapter), newLabel: "SablierLidoAdapter" });
    }

    /// @dev Deploys external Lido/Curve protocol mocks at the mainnet constant addresses.
    function deployExternalMocks() internal {
        weth = new MockWETH9();
        steth = new MockStETH();
        wstEth = new MockWstETH(address(steth));
        curvePool = new MockCurvePool(address(steth));

        // Fund Curve pool with ETH for swaps.
        vm.deal(address(curvePool), 10_000 ether);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  VAULT CREATION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates a default vault.
    function createDefaultVault() internal returns (uint256 vaultId) {
        vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    /// @dev Creates a vault with the specified token.
    function createVaultWithToken(IERC20 token) internal returns (uint256 vaultId) {
        vaultId = bob.createVault({ token: token, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    /// @dev Creates a vault with an adapter configured.
    function createVaultWithAdapter() internal returns (uint256 vaultId) {
        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(weth, adapter);

        setMsgSender(users.depositor);
        vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });

        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(weth, ISablierBobAdapter(address(0)));

        setMsgSender(users.depositor);
    }

    /// @dev Creates a vault that will be expired at the current block timestamp.
    function createExpiredVault() internal returns (uint256 vaultId) {
        // Create vault with expiry in the future.
        vaultId = bob.createVault({ token: weth, oracle: oracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });

        // Warp past expiry to make it settled.
        vm.warp({ newTimestamp: EXPIRY + 1 });
    }

    /// @dev Creates a vault that is settled via price reaching target.
    function createSettledVaultViaPrice() internal returns (uint256 vaultId) {
        vaultId = createDefaultVault();

        // Set oracle price to target.
        oracle.setPrice(TARGET_PRICE);

        // Sync the vault to update the price.
        bob.syncPriceFromOracle(vaultId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    DEPOSITS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Makes a deposit into a vault.
    function depositIntoVault(uint256 vaultId, uint128 amount) internal {
        bob.enter(vaultId, amount);
    }

    /// @dev Makes a deposit into a vault from a specific user.
    function depositIntoVaultFrom(uint256 vaultId, uint128 amount, address user) internal {
        setMsgSender(user);
        bob.enter(vaultId, amount);
    }
}
