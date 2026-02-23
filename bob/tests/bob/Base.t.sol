// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import {
    ChainlinkOracleMock,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleWithRevertingPrice,
    ChainlinkOracleZeroPrice
} from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { BaseTest as EvmBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { SablierBob } from "src/SablierBob.sol";
import { SablierLidoAdapter } from "src/SablierLidoAdapter.sol";

import { MockCurvePool, MockStETH, MockWstETH } from "./mocks/MockLido.sol";
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

    ISablierBob internal bob;
    ISablierLidoAdapter internal adapter;
    AggregatorV3Interface internal chainlinkOracle;
    ChainlinkOracleMock internal mockOracle;
    ChainlinkOracleWith18Decimals internal mockOracleInvalidDecimals;
    ChainlinkOracleZeroPrice internal mockOracleInvalidPrice;
    ChainlinkOracleWithRevertingDecimals internal mockOracleReverting;
    ChainlinkOracleWithRevertingPrice internal mockOracleRevertingOnLatestRoundData;

    // External protocol mocks (Lido ecosystem).
    IERC20 internal weth;
    MockStETH internal steth;
    MockWstETH internal wstEth;
    MockCurvePool internal curvePool;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        EvmBase.setUp();

        // Set the Bob protocol fee in the comptroller.
        setMsgSender(admin);
        comptroller.setMinFeeUSD(ISablierComptroller.Protocol.Bob, BOB_MIN_FEE_USD);

        // Deploy mock oracles.
        mockOracle = new ChainlinkOracleMock();
        chainlinkOracle = AggregatorV3Interface(address(mockOracle));
        mockOracle.setPrice(uint256(CURRENT_PRICE));
        mockOracleInvalidDecimals = new ChainlinkOracleWith18Decimals();
        mockOracleInvalidPrice = new ChainlinkOracleZeroPrice();
        mockOracleReverting = new ChainlinkOracleWithRevertingDecimals();
        mockOracleRevertingOnLatestRoundData = new ChainlinkOracleWithRevertingPrice();

        // Label the mock oracles.
        vm.label({ account: address(mockOracle), newLabel: "ChainlinkOracleMock" });
        vm.label({ account: address(mockOracleInvalidDecimals), newLabel: "ChainlinkOracleWith18Decimals" });
        vm.label({ account: address(mockOracleInvalidPrice), newLabel: "ChainlinkOracleZeroPrice" });
        vm.label({ account: address(mockOracleReverting), newLabel: "ChainlinkOracleWithRevertingDecimals" });
        vm.label({
            account: address(mockOracleRevertingOnLatestRoundData),
            newLabel: "ChainlinkOracleWithRevertingPrice"
        });

        // Deploy the protocol.
        deployProtocol();

        // Deploy external Lido/Curve mocks.
        deployExternalMocks();

        // Deploy the real adapter with external mocks.
        deployAdapter();

        // Create test users.
        createTestUsers();

        // Warp to Feb 1, 2025 at 00:00 UTC to provide a more realistic testing environment.
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
        users.bob = createUser("Bob", spenders);

        // Give ETH to users, deposit into WETH, and approve Bob.
        vm.deal(users.depositor, 1000 ether);
        vm.deal(users.bob, 1000 ether);
        vm.deal(users.alice, 1000 ether);

        vm.startPrank(users.depositor);
        IWETH9(address(weth)).deposit{ value: 1000 ether }();
        weth.approve(address(bob), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(users.bob);
        IWETH9(address(weth)).deposit{ value: 1000 ether }();
        weth.approve(address(bob), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(users.alice);
        IWETH9(address(weth)).deposit{ value: 1000 ether }();
        weth.approve(address(bob), type(uint256).max);
        vm.stopPrank();
    }

    /// @dev Deploys the SablierBob protocol.
    function deployProtocol() internal {
        bob = new SablierBob(address(comptroller));
        vm.label({ account: address(bob), newLabel: "SablierBob" });
    }

    /// @dev Deploys external Lido/Curve protocol mocks at the mainnet constant addresses.
    function deployExternalMocks() internal {
        // Mainnet addresses used as constants in SablierLidoAdapter.
        address payable wethMainnet = payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        address payable stethMainnet = payable(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
        address payable wstEthMainnet = payable(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        address payable curvePoolMainnet = payable(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

        // Deploy WETH mock at mainnet address using deployCodeTo.
        deployCodeTo("MockLido.sol:MockWETH9", wethMainnet);
        weth = IERC20(wethMainnet);
        vm.label({ account: wethMainnet, newLabel: "WETH" });

        // Deploy stETH mock at mainnet address.
        deployCodeTo("MockLido.sol:MockStETH", stethMainnet);
        steth = MockStETH(stethMainnet);
        vm.label({ account: stethMainnet, newLabel: "stETH" });

        // Deploy wstETH mock at mainnet address with mainnet stETH constructor arg.
        deployCodeTo("MockLido.sol:MockWstETH", abi.encode(stethMainnet), wstEthMainnet);
        wstEth = MockWstETH(wstEthMainnet);
        vm.label({ account: wstEthMainnet, newLabel: "wstETH" });

        // Deploy Curve pool mock at mainnet address with mainnet stETH constructor arg.
        deployCodeTo("MockLido.sol:MockCurvePool", abi.encode(stethMainnet), curvePoolMainnet);
        curvePool = MockCurvePool(curvePoolMainnet);
        vm.label({ account: curvePoolMainnet, newLabel: "CurvePool" });

        // Fund Curve pool with ETH for swaps.
        vm.deal(curvePoolMainnet, 10_000 ether);
    }

    /// @dev Deploys the real SablierLidoAdapter.
    function deployAdapter() internal {
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

    /*//////////////////////////////////////////////////////////////////////////
                                  VAULT CREATION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates a default vault with WETH (no adapter) and returns the vault ID.
    /// If a default adapter is already set for WETH, it is temporarily unset and restored after vault creation.
    function createDefaultVault() internal returns (uint256 vaultId) {
        // Snapshot and clear any default adapter for WETH so the vault has no adapter.
        ISablierBobAdapter currentAdapter = bob.getDefaultAdapterFor(weth);
        if (address(currentAdapter) != address(0)) {
            setMsgSender(address(comptroller));
            bob.setDefaultAdapter(weth, ISablierBobAdapter(address(0)));
            setMsgSender(users.depositor);
        }

        vaultId = bob.createVault({ token: weth, oracle: chainlinkOracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });

        // Restore the adapter.
        if (address(currentAdapter) != address(0)) {
            setMsgSender(address(comptroller));
            bob.setDefaultAdapter(weth, currentAdapter);
            setMsgSender(users.depositor);
        }
    }

    /// @dev Creates a vault with the specified token.
    function createVaultWithToken(IERC20 token) internal returns (uint256 vaultId) {
        vaultId = bob.createVault({ token: token, oracle: chainlinkOracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    /// @dev Creates a vault with an adapter configured.
    function createVaultWithAdapter() internal returns (uint256 vaultId) {
        // Set the default adapter for WETH.
        setMsgSender(address(comptroller));
        bob.setDefaultAdapter(weth, adapter);

        setMsgSender(users.depositor);
        vaultId = bob.createVault({ token: weth, oracle: chainlinkOracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });
    }

    /// @dev Creates a vault that will be expired at the current block timestamp.
    function createExpiredVault() internal returns (uint256 vaultId) {
        // Create vault with expiry in the future.
        vaultId = bob.createVault({ token: weth, oracle: chainlinkOracle, expiry: EXPIRY, targetPrice: TARGET_PRICE });

        // Warp past expiry to make it settled.
        vm.warp({ newTimestamp: EXPIRY + 1 });
    }

    /// @dev Creates a vault that is settled via price reaching target.
    function createSettledVaultViaPrice() internal returns (uint256 vaultId) {
        vaultId = createDefaultVault();

        // Set oracle price to target.
        mockOracle.setPrice(TARGET_PRICE);

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
