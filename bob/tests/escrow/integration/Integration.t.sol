// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all integration tests, both concrete and fuzz tests.
abstract contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal defaultOrderId;
    uint256 internal nullOrderId = 1729;

    /*//////////////////////////////////////////////////////////////////////////
                                       SET-UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Use DAI as sell token and USDC as buy token.
        sellToken = dai;
        buyToken = usdc;

        // Set seller as the default caller for the tests.
        setMsgSender(users.seller);

        // Create the default order.
        defaultOrderId = createDefaultOrder();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                COMMON-REVERT-TESTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a revert when the order is null.
    function expectRevert_Null(bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(escrow).call(callData);
        assertFalse(success, "null order call success");
        assertEq(
            returnData,
            abi.encodeWithSelector(Errors.SablierEscrowState_Null.selector, nullOrderId),
            "null order call return data"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates an order with default values.
    function createDefaultOrder() internal returns (uint256 orderId) {
        orderId = createDefaultOrder(users.buyer);
    }

    /// @dev Creates an order with a specified buyer.
    function createDefaultOrder(address buyer) internal returns (uint256 orderId) {
        orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: buyer,
            expiryTime: ORDER_EXPIRY_TIME
        });
    }
}
