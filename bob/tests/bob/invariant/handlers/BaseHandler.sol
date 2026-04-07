// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ChainlinkOracleMock } from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Bob } from "src/types/Bob.sol";

import { MockWstETH } from "../../mocks/MockWstETH.sol";
import { Constants } from "../../utils/Constants.sol";
import { Store } from "../stores/Store.sol";

/// @notice Base contract with common logic needed by {BobHandler} and {LidoAdapterHandler}.
abstract contract BaseHandler is Constants, StdCheats, BaseUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps function names to their call counts.
    mapping(string func => uint256 count) public calls;

    /// @dev The current token selected by the fuzzer.
    IERC20 public currentToken;

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
    IERC20 public weth;
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

    /// @dev Checks user assumptions.
    modifier checkUser(address user) {
        _assumeValidUser(user);
        _;
    }

    /// @dev Checks user assumptions for two users.
    modifier checkUsers(address user0, address user1) {
        _assumeValidUser(user0);
        _assumeValidUser(user1);
        vm.assume(user0 != user1);
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
        IERC20 weth_,
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

    function recordStatuses() external instrument("recordStatuses") {
        _recordStatuses();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Filters out addresses that cannot be used as users (zero, precompiles, known contracts).
    function _assumeValidUser(address user) internal view {
        vm.assume(user > address(9));
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

    /// @dev Snapshots the current status and isStakedInAdapter for all vaults as pre-state.
    function _recordStatuses() internal {
        for (uint256 i = 0; i < store.vaultCount(); ++i) {
            uint256 vaultId = store.vaultIds(i);
            store.setPrevStatus(vaultId, uint8(bob.statusOf(vaultId)));
            store.setPrevIsStakedInAdapter(vaultId, bob.isStakedInAdapter(vaultId));
        }
    }

    /// @dev Settles a vault by temporarily raising oracle price to target.
    ///      For adapter vaults, also simulates yield by lowering the wstETH exchange rate
    ///      (each wstETH unwraps to more stETH, creating a net gain).
    function _settleVault(uint256 vaultId) internal {
        if (bob.statusOf(vaultId) == Bob.Status.ACTIVE) {
            oracle.setPrice(TARGET_PRICE);
            setMsgSender(address(this));
            bob.syncPriceFromOracle(vaultId);
            oracle.setPrice(CURRENT_PRICE);
        }

        if (address(bob.getAdapter(vaultId)) != address(0) && bob.isStakedInAdapter(vaultId)) {
            wstEth.setExchangeRate(UD60x18.wrap(0.8e18));
        }
    }
}
