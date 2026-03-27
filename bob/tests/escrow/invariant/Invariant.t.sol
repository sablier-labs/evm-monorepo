// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdInvariant } from "forge-std/src/StdInvariant.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Base_Test } from "../Base.t.sol";
import { EscrowHandler } from "./handlers/EscrowHandler.sol";
import { Store } from "./stores/Store.sol";

/// @notice Invariant tests for {SablierEscrow}.
contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    EscrowHandler internal handler;
    Store internal store;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the contracts.
        store = new Store();
        handler = new EscrowHandler({ store_: store, escrow_: escrow });

        // Label the contracts.
        vm.label({ account: address(store), newLabel: "Store" });
        vm.label({ account: address(handler), newLabel: "EscrowHandler" });

        // Target the handler for invariant testing.
        targetContract(address(handler));

        // Prevent these addresses from being fuzzed as `msg.sender`.
        excludeSender(address(escrow));
        excludeSender(address(comptroller));
        excludeSender(address(handler));
        excludeSender(address(store));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev For a given filled order:
    /// - Sell side: amount transferred to buyer + amount transferred to comptroller = sell amount.
    /// - Buy side: amount transferred to seller + amount transferred to comptroller = buy amount.
    function invariant_AmountConservationOnFill() external view {
        for (uint256 i = 0; i < store.orderCount(); ++i) {
            uint256 orderId = store.orderIds(i);

            // Skip if order is not filled.
            if (!escrow.wasFilled(orderId)) continue;

            Store.FillData memory data = store.getFillData(orderId);
            assertEq(
                data.amountToTransferToBuyer + data.feeDeductedFromBuyerAmount,
                escrow.getSellAmount(orderId),
                "Invariant violation: amount transferred to buyer + amount transferred to comptroller != sell amount"
            );

            assertEq(
                data.amountToTransferToSeller + data.feeDeductedFromSellerAmount,
                data.buyAmount,
                "Invariant violation: amount transferred to seller + amount transferred to comptroller != buy amount"
            );
        }
    }

    /// @dev For a given sell token, the escrow's balance equals the sum of sell amounts across all open and expired
    /// orders.
    function invariant_ContractBalancePerSellToken() external view {
        for (uint256 t = 0; t < store.tokensCount(); ++t) {
            IERC20 token = store.tokens(t);
            uint256 expectedBalance = 0;

            for (uint256 i = 0; i < store.orderCount(); ++i) {
                uint256 orderId = store.orderIds(i);
                bool isOpenOrExpired =
                    escrow.statusOf(orderId) == Escrow.Status.OPEN || escrow.statusOf(orderId) == Escrow.Status.EXPIRED;
                if (escrow.getSellToken(orderId) == token && isOpenOrExpired) {
                    expectedBalance += escrow.getSellAmount(orderId);
                }
            }

            assertEq(
                token.balanceOf(address(escrow)),
                expectedBalance,
                "Invariant violation: contract balance != sum of sell amounts of all open and expired orders"
            );
        }
    }

    /// @dev Inv 36: On cancellation, the full sellAmount must be returned to the seller.
    function invariant_CancellationReturnsFullSellAmount() external view {
        for (uint256 i = 0; i < store.cancelRecordCount(); ++i) {
            Store.CancelData memory data = store.getCancelRecord(i);
            assertEq(
                data.sellerBalanceAfter - data.sellerBalanceBefore,
                data.sellAmount,
                "Invariant violation: cancellation did not return full sellAmount to seller"
            );
        }
    }

    /// @dev Inv 50: wasFilled and wasCanceled must never both be true for the same order.
    function invariant_FilledAndCanceledMutuallyExclusive() external view {
        for (uint256 i = 0; i < store.orderCount(); ++i) {
            uint256 orderId = store.orderIds(i);
            bool filled = escrow.wasFilled(orderId);
            bool canceled = escrow.wasCanceled(orderId);
            assertFalse(
                filled && canceled,
                "Inv 50: wasFilled and wasCanceled both true for same order"
            );
        }
    }
}
