// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { ChainlinkOracleMock } from "@sablier/evm-utils/src/mocks/ChainlinkMocks.sol";
import { ISablierBob } from "src/interfaces/ISablierBob.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Bob } from "src/types/Bob.sol";

import { MockWstETH } from "../../mocks/MockWstETH.sol";
import { Store } from "../stores/Store.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @notice Handler for the invariant tests of {SablierLidoAdapter} contract.
contract LidoAdapterHandler is BaseHandler {
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
    )
        BaseHandler(store_, bob_, adapter_, weth_, wstEth_, oracle_, comptroller_)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function requestLidoWithdrawal(
        uint256 vaultIdSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("requestLidoWithdrawal")
        adjustTimestamp(timeJumpSeed)
        vaultCountNotZero
    {
        uint256 vaultId = _fuzzVaultId(vaultIdSeed);

        // Skip if vault has no adapter.
        if (address(bob.getAdapter(vaultId)) == address(0)) return;

        // Skip if vault is still active.
        if (bob.statusOf(vaultId) == Bob.Status.ACTIVE) return;

        // Skip if vault is already unstaked.
        if (!bob.isStakedInAdapter(vaultId)) return;

        // Skip if no one has deposited into this vault.
        if (store.totalDeposited(vaultId) == 0) return;

        // Skip if Lido withdrawal has already been requested.
        if (adapter.getLidoWithdrawalRequestIds(vaultId).length > 0) return;

        setMsgSender(comptroller);
        adapter.requestLidoWithdrawal(vaultId);
    }

    function setYieldFee(
        uint256 feeSeed,
        uint256 timeJumpSeed
    )
        external
        instrument("setYieldFee")
        adjustTimestamp(timeJumpSeed)
    {
        if (calls["setYieldFee"] > MAX_ADMIN_CALLS) return;

        UD60x18 newFee = UD60x18.wrap(_bound(feeSeed, 0, 0.2e18));

        setMsgSender(comptroller);
        adapter.setYieldFee(newFee);
    }
}
