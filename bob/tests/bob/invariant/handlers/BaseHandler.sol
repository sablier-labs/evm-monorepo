// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";
import { ChainlinkOracleMock } from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { IBobVaultShare } from "src/interfaces/IBobVaultShare.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Bob } from "src/types/Bob.sol";
import { MockWstETH } from "../../mocks/MockWstETH.sol";
import { Constants } from "../../utils/Constants.sol";
import { Store } from "../stores/Store.sol";

/// @notice Base contract with common logic needed by handlers.
abstract contract BaseHandler is Constants, StdCheats, BaseUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps function names to their call counts.
    mapping(string func => uint256 count) public calls;

    /// @dev The current token selected by the fuzzer.
    IERC20 public currentToken;

    /// @dev Maximum number of admin config calls (e.g. setYieldFee) per run.
    uint256 internal constant MAX_ADMIN_CALLS = 10;

    /// @dev Maximum number of vaults that can be created during invariant runs.
    uint256 internal constant MAX_VAULT_COUNT = 10;

    /// @dev Total calls across all handler functions.
    uint256 public totalCalls;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierLidoAdapter public adapter;
    ISablierBob public bob;
    address public comptroller;
    ChainlinkOracleMock public oracle;
    Store public store;
    IWETH9 public weth;
    MockWstETH public wstEth;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Simulates the passage of time. The time jump is kept under 15 days.
    modifier adjustTimestamp(uint256 timeJumpSeed) {
        uint256 timeJump = _bound(timeJumpSeed, 0, 15 days);
        skip(timeJump);
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory functionName) {
        calls[functionName]++;
        totalCalls++;
        _;
    }

    /// @dev Selects a random token from the store's token list.
    modifier useFuzzedToken(uint256 tokenIndex) {
        IERC20[] memory tokens = store.getTokens();
        tokenIndex = _bound(tokenIndex, 0, tokens.length - 1);
        currentToken = tokens[tokenIndex];
        _;
    }

    /// @dev Skip if no vaults exist.
    modifier vaultCountNotZero() {
        if (store.vaultCount() == 0) return;
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        Store store_,
        ISablierBob bob_,
        ISablierLidoAdapter adapter_,
        IWETH9 weth_,
        MockWstETH wstEth_,
        ChainlinkOracleMock oracle_,
        address comptroller_
    ) {
        store = store_;
        bob = bob_;
        adapter = adapter_;
        weth = weth_;
        wstEth = wstEth_;
        oracle = oracle_;
        comptroller = comptroller_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Increases the oracle price by 10%, simulating real-world price appreciation.
    function increaseOraclePrice(uint256 timeJumpSeed)
        external
        instrument("increaseOraclePrice")
        adjustTimestamp(timeJumpSeed)
    {
        uint256 currentPrice = uint256(oracle.price());
        uint256 newPrice = currentPrice * 110 / 100;
        oracle.setPrice(newPrice);
    }

    /// @dev Raises the wstETH exchange rate, simulating a Lido slashing event. A higher rate means each wstETH unwraps
    /// to less stETH.
    function simulateLidoSlashing(
        uint256 slashingSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("simulateLidoSlashing")
        adjustTimestamp(timeJumpSeed)
    {
        // Limit this call.
        if (calls["simulateLidoSlashing"] > MAX_ADMIN_CALLS) return;

        // Only triggers ~1% of the time to reflect real-world scenario.
        if (slashingSeed % 100 != 0) return;

        UD60x18 currentRate = wstEth.exchangeRate();
        wstEth.setExchangeRate(currentRate.mul(ud(1.02e18)));
    }

    /// @dev Lowers the wstETH exchange rate by 1%, simulating staking yield accumulation. A lower rate means each
    /// wstETH unwraps to more stETH.
    function simulateLidoYield(uint256 timeJumpSeed)
        external
        instrument("simulateLidoYield")
        adjustTimestamp(timeJumpSeed)
    {
        // Limit this call.
        if (calls["simulateLidoYield"] > MAX_ADMIN_CALLS) return;

        UD60x18 currentRate = wstEth.exchangeRate();
        wstEth.setExchangeRate(currentRate.mul(ud(0.99e18)));
    }

    /// @dev A helper function to transfer shares between users.
    function transferShares(
        uint256 vaultIdSeed,
        address from,
        address to,
        uint128 amountSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("transferShares")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        _assumeValidUser(from);
        _assumeValidUser(to);

        // Ensure from and to are different users.
        vm.assume(from != to);

        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        IBobVaultShare shareToken = bob.getShareToken(vaultId);
        uint256 shareBalance = shareToken.balanceOf(from);

        // Skip if from has no shares.
        if (shareBalance == 0) return;

        uint128 minAmount = 1;

        // For adapter vaults, ensure the transfer amount is large enough so proportional wstETH is not zero.
        if (address(bob.getAdapter(vaultId)) != address(0)) {
            uint128 fromWstETH = adapter.getYieldBearingTokenBalanceFor(vaultId, from);
            if (fromWstETH == 0) return;
            minAmount = uint128((shareBalance + fromWstETH - 1) / fromWstETH);
        }

        uint128 amount = boundUint128(amountSeed, minAmount, uint128(shareBalance));

        setMsgSender(from);
        IERC20(address(shareToken)).transfer(to, amount);
        store.addUser(vaultId, to);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Filters out addresses that cannot be used as users.
    function _assumeValidUser(address user) internal view {
        vm.assume(user != address(0));
        vm.assume(user != address(this));
        vm.assume(user != address(bob));
        vm.assume(user != address(adapter));
        vm.assume(user != comptroller);
        vm.assume(user != address(store));
        vm.assume(user != address(weth));
        vm.assume(user != address(wstEth));
        vm.assume(user != address(oracle));
    }

    /// @dev Returns a random vault ID from the store.
    function _fuzzVaultId(uint256 seed) internal view returns (uint256) {
        uint256 index = seed % store.vaultCount();
        return store.vaultIds(index);
    }

    /// @dev Records the oracle price when a vault becomes settled for the first time.
    function _recordPriceAtSettlement(uint256 vaultId) internal {
        // Skip if vault is not settled or the price has already been recorded.
        if (bob.statusOf(vaultId) == Bob.Status.SETTLED && store.priceAtSettlement(vaultId) == 0) {
            uint128 lastSyncedPrice = bob.getLastSyncedPrice(vaultId);
            store.setPriceAtSettlement(vaultId, lastSyncedPrice);
        }
    }
}
