// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all Escrow fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal constant FORK_SELL_TOKEN = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH
    IERC20 internal constant FORK_BUY_TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at the latest block number.
        vm.createSelectFork({ urlOrAlias: "ethereum" });

        // Load deployed contracts from Ethereum Mainnet.
        escrow = ISablierEscrow(0xe1662e09e68b700A0C17F17BD08445EC1de0d206);
        comptroller = ISablierComptroller(0x0000008ABbFf7a84a2fE09f9A9b74D3BC2072399);

        // Label the contracts and tokens.
        vm.label(address(escrow), "SablierEscrow");
        vm.label(address(FORK_SELL_TOKEN), "sellToken: weth");
        vm.label(address(FORK_BUY_TOKEN), "buyToken: usdc");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks the fuzzed users.
    function checkUsers(address seller, address buyer) internal virtual {
        vm.assume(seller != address(0) && buyer != address(0));
        vm.assume(seller != buyer);
        vm.assume(seller != address(escrow) && buyer != address(escrow));
        vm.assume(seller != address(comptroller) && buyer != address(comptroller));

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_SELL_TOKEN), seller);
        assumeNoBlacklisted(address(FORK_SELL_TOKEN), buyer);
        assumeNoBlacklisted(address(FORK_BUY_TOKEN), seller);
        assumeNoBlacklisted(address(FORK_BUY_TOKEN), buyer);
    }
}
