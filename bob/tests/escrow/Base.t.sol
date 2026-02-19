// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { SablierEscrow } from "src/SablierEscrow.sol";

import { Assertions } from "./utils/Assertions.sol";
import { Modifiers } from "./utils/Modifiers.sol";

/// @notice Base test contract with common logic needed by all Escrow tests.
abstract contract Base_Test is Assertions, Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierEscrow internal escrow;

    // Token contracts.
    IERC20 internal sellToken;
    IERC20 internal buyToken;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // Deploy the Escrow protocol.
        escrow = new SablierEscrow(address(comptroller), DEFAULT_TRADE_FEE);
        vm.label({ account: address(escrow), newLabel: "SablierEscrow" });

        // Create test users.
        address[] memory spenders = new address[](1);
        spenders[0] = address(escrow);
        users.alice = createUser("Alice", spenders);
        users.seller = createUser("Seller", spenders);
        users.buyer = createUser("Buyer", spenders);

        // Set modifier variables.
        setVariables(users);

        // Warp to Feb 1, 2026 at 00:00 UTC to provide a more realistic testing environment.
        vm.warp({ newTimestamp: FEB_1_2026 });
    }
}
