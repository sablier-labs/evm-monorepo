// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_TOKEN;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) {
        FORK_TOKEN = forkToken;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at the latest block number.
        vm.createSelectFork({ urlOrAlias: "ethereum" });

        // Load mainnet address.
        flow = ISablierFlow(0x844344Cd871B28221d725ecE9630E8bDE4E3a181);

        // Label the flow contract.
        vm.label(address(flow), "Flow");

        // Label the addresses.
        labelForkedToken(FORK_TOKEN);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks the fuzzed users.
    /// @dev The reason for not using `vm.assume` is because the compilation takes longer.
    function checkUsers(address sender, address recipient) internal virtual {
        vm.assume(sender != address(0) && recipient != address(0));
        vm.assume(sender != address(flow) && recipient != address(flow));

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_TOKEN), sender);
        assumeNoBlacklisted(address(FORK_TOKEN), recipient);
    }

    /// @dev Helper function to deposit on a stream.
    function depositOnStream(uint256 streamId, uint128 depositAmount) internal {
        address sender = flow.getSender(streamId);
        setMsgSender(sender);
        deal({ token: address(FORK_TOKEN), to: sender, give: depositAmount });

        // Use `forceApprove` for USDT compatibility.
        FORK_TOKEN.forceApprove(address(flow), depositAmount);

        flow.deposit({
            streamId: streamId,
            amount: depositAmount,
            sender: sender,
            recipient: flow.getRecipient(streamId)
        });
    }
}
